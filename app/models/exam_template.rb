require 'fileutils'

class ExamTemplate < ApplicationRecord
  before_validation :set_defaults_for_name, :set_formats_for_name_and_filename
  before_save :undo_mark_for_destruction
  after_create_commit :create_base_path
  belongs_to :assignment, foreign_key: :assessment_id, inverse_of: :exam_templates
  has_one :course, through: :assignment
  validates :filename, :num_pages, :name, presence: true
  validates :name,
            uniqueness: { scope: :assignment }
  validates :num_pages, numericality: { greater_than_or_equal_to: 0,
                                        only_integer: true }

  has_many :split_pdf_logs, dependent: :destroy
  has_many :template_divisions, dependent: :destroy
  accepts_nested_attributes_for :template_divisions,
                                allow_destroy: true,
                                update_only: true,
                                reject_if: :exam_been_uploaded?

  # Create an ExamTemplate with the correct file
  def self.create_with_file(blob, attributes = {})
    return unless attributes.key? :assessment_id
    assignment = Assignment.find(attributes[:assessment_id])
    filename = attributes[:filename].tr(' ', '_')
    name_input = attributes[:name]
    pdf = CombinePDF.parse blob
    num_pages = pdf.pages.length
    if name_input == ''
      new_template = ExamTemplate.new(
        filename: filename,
        num_pages: num_pages,
        assessment_id: assignment.id
      )
    else
      new_template = ExamTemplate.new(
        name: name_input,
        filename: filename,
        num_pages: num_pages,
        assessment_id: assignment.id
      )
    end
    saved = new_template.save
    if saved
      File.binwrite(new_template.file_path, blob)
      new_template.save_cover
    end
    new_template
  end

  # Replace an ExamTemplate with the correct file
  def replace_with_file(blob, attributes = {})
    File.binwrite(self.file_path, blob)

    pdf = CombinePDF.parse blob
    self.update(num_pages: pdf.pages.length, filename: attributes[:new_filename])
    self.save_cover
  end

  def delete_with_file
    FileUtils.rm_rf base_path
    FileUtils.rm_f file_path
    self.destroy
  end

  # Split up PDF file based on this exam template.
  def split_pdf(path, original_filename = nil, current_role = nil, on_duplicate = nil, current_user = nil)
    basename = File.basename path, '.pdf'
    filename = original_filename.nil? ? basename : File.basename(original_filename)
    pdf = CombinePDF.load path
    num_pages = pdf.pages.length

    # creating an instance of split_pdf_log
    split_pdf_log = SplitPdfLog.create(
      exam_template: self,
      filename: filename,
      original_num_pages: num_pages,
      num_groups_in_complete: 0,
      num_groups_in_incomplete: 0,
      num_pages_qr_scan_error: 0,
      role: current_role
    )

    raw_dir = File.join(self.base_path, 'raw')
    FileUtils.mkdir_p raw_dir
    FileUtils.cp path, File.join(raw_dir, "raw_upload_#{split_pdf_log.id}.pdf")

    SplitPdfJob.perform_later(self,
                              path,
                              split_pdf_log,
                              original_filename,
                              current_role,
                              on_duplicate,
                              current_user)
  end

  def fix_error(filename, exam_num, page_num, upside_down)
    error_file = File.join(
      base_path, 'error', filename
    )
    complete_dir = File.join(
      base_path, 'complete', exam_num
    )
    incomplete_dir = File.join(
      base_path, 'incomplete', exam_num
    )

    unless File.exist? error_file
      raise I18n.t('exam_templates.assign_errors.errors.file_not_found', filename: error_file)
    end
    exam_num = Integer(exam_num)
    page_num = Integer(page_num)
    if page_num < 1 || page_num > self.num_pages
      raise I18n.t('exam_templates.assign_errors.errors.invalid_page_number', page_num: page_num)
    end
    if exam_num < 1
      raise I18n.t('exam_templates.assign_errors.errors.invalid_exam_number', exam_num: exam_num)
    end

    # if file is missing from complete group
    # if there isn't corresponding file in incomplete group
    unless File.exist?(File.join(complete_dir, page_num.to_s)) && !File.exist?(File.join(incomplete_dir, page_num.to_s))
      # Update status of split_page to be FIXED
      split_page_id = File.basename(filename, '.pdf') # since filename is "#{split_page.id}.pdf"
      split_page = SplitPage.find(split_page_id)
      group = Group.find_or_create_by!(
        group_name: "#{self.name}_paper_#{exam_num}",
        repo_name: "#{self.name}_paper_#{exam_num}",
        course: self.course
      )
      split_page.update!(status: 'FIXED', exam_page_number: page_num, group: group)
      # This creates both a new grouping and a new folder in the group repository
      # when a new group is entered.
      grouping = Grouping.find_or_create_by!(
        group_id: group.id,
        assessment_id: self.assessment_id
      )

      # if incomplete directory doesn't exist yet
      FileUtils.mkdir_p incomplete_dir
      # move the file into incomplete group
      FileUtils.mv(error_file, incomplete_dir)
      # rename the error file into page_num.pdf
      error_file_old_name = File.join(incomplete_dir, filename)
      error_file_new_name = File.join(incomplete_dir, "#{page_num}.pdf")
      File.rename(error_file_old_name, error_file_new_name)
      if upside_down
        new_pdf = CombinePDF.new
        pdf = CombinePDF.load(error_file_new_name)
        pdf.pages.each do |page|
          new_pdf << page.fix_rotation
        end
        File.binwrite(error_file_new_name, new_pdf.to_pdf)
      end

      # add assignment files based on template divisions
      grouping.access_repo do |repo|
        revision = repo.get_latest_revision
        assignment_folder = self.assignment.repository_folder
        txn = repo.get_transaction(self.course.instructors.first.user_name)
        self.template_divisions.each do |template_division|
          next unless page_num.to_i.between?(template_division.start, template_division.end)

          submission_file = CombinePDF.new
          (template_division.start..template_division.end).each do |i|
            path = File.join(incomplete_dir, "#{i}.pdf")
            if File.exist? path
              pdf = CombinePDF.load path
              submission_file << pdf.pages[0]
            end
          end
          target_path = File.join(assignment_folder, "#{template_division.label}.pdf")
          if revision.path_exists? target_path
            txn.replace(File.join(assignment_folder, "#{template_division.label}.pdf"), submission_file.to_pdf,
                        'application/pdf', revision.revision_identifier)
          else
            txn.add(target_path, submission_file.to_pdf)
          end
        end

        # update COVER.pdf if error page given is first page of exam template
        if page_num.to_i == 1
          path = File.join(incomplete_dir, "#{page_num}.pdf")
          if File.exist? path
            cover_pdf = CombinePDF.new
            pdf = CombinePDF.load path
            cover_pdf << pdf.pages[0]
            target_path = File.join(assignment_folder, 'COVER.pdf')
            if revision.path_exists? target_path
              txn.replace(target_path, cover_pdf.to_pdf,
                          'application/pdf', revision.revision_identifier)
            else
              txn.add(target_path, cover_pdf.to_pdf)
            end
          end
        end

        # update EXTRA.pdf
        extra_pdf = CombinePDF.new
        if Dir.exist?(incomplete_dir)
          Dir.entries(incomplete_dir).sort.each do |file_in_dir|
            path = File.join(incomplete_dir, file_in_dir)
            basename = File.basename file_in_dir # For example, 3 from 3.pdf
            page_number = basename.to_i
            # if it is an extra page, add it to extra_pdf
            next unless File.exist? path
            next if file_in_dir.start_with? '.'
            next unless template_divisions.all? { |div| div.start > page_number || div.end < page_number }
            next if page_number == 1

            pdf = CombinePDF.load path
            extra_pdf << pdf.pages[0]
          end
          target_path = File.join(assignment_folder, 'EXTRA.pdf')
          if revision.path_exists? target_path
            txn.replace(target_path, extra_pdf.to_pdf,
                        'application/pdf', revision.revision_identifier)
          else
            txn.add(target_path, extra_pdf.to_pdf)
          end
        end

        repo.commit(txn)
      end
    end
  end

  def base_path
    return @base_path if defined? @base_path
    @base_path = File.join self.assignment.scanned_exams_path, self.id.to_s
  end

  def file_path
    File.join(base_path, 'exam_template.pdf')
  end

  def tmp_path
    Rails.root.join "tmp/exam_templates/#{self.id}/"
  end

  def generated_copies_file_name(num_copies, start)
    "#{self.name}-#{start}-#{start + num_copies - 1}.pdf"
  end

  def num_cover_fields
    self.cover_fields.split(',').length
  end

  def get_cover_field(idx)
    if self.num_cover_fields > idx
      self.cover_fields.split(',')[idx]
    else
      ' '
    end
  end

  def save_cover
    pdf = CombinePDF.load file_path
    return if pdf.pages.empty?
    cover = pdf.pages[0]
    cover_page = CombinePDF.new
    cover_page << cover
    imglist = Magick::Image.from_blob(cover_page.to_pdf) do |options|
      options.quality = 100
      options.density = '300'
    end
    imglist.first.write(File.join(self.base_path, 'cover.jpg'))
  end

  # any changes to template divisions should be rejected once exams have been uploaded
  def exam_been_uploaded?
    self.split_pdf_logs.exists?
  end

  private

  # name and filename shouldn't include whitespace
  def set_formats_for_name_and_filename
    self.name = self.name.tr(' ', '_')
    self.filename = self.filename.tr(' ', '_')
  end

  def set_defaults_for_name
    if self.name.blank?
      # Attribute 'name' of exam template is by default set to filename without extension
      extension = File.extname self.filename
      self.name = File.basename self.filename, extension
    end
  end

  # any attempts to delete template divisions should be rejected once exams have been uploaded
  def undo_mark_for_destruction
    template_divisions.each { |div| div.reload if div.marked_for_destruction? } if exam_been_uploaded?
  end

  def create_base_path
    FileUtils.mkdir_p self.base_path
  end
end
