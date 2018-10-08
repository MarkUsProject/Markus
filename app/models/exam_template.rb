require 'fileutils'

class ExamTemplate < ApplicationRecord
  before_save :set_formats_for_name_and_filename
  after_initialize :set_defaults_for_name, unless: :persisted? # will only work if the object is new
  after_update :rename_exam_template_directory
  belongs_to :assignment
  validates :filename, :num_pages, :name, presence: true
  validates_uniqueness_of :name,
                          scope: :assignment
  validates :num_pages, numericality: { greater_than_or_equal_to: 0,
                                        only_integer: true }

  has_many :split_pdf_logs, dependent: :destroy
  has_many :template_divisions, dependent: :destroy
  accepts_nested_attributes_for :template_divisions, allow_destroy: true, update_only: true, reject_if: :exam_been_uploaded?

  # Create an ExamTemplate with the correct file
  def self.create_with_file(blob, attributes={})
    return unless attributes.has_key? :assignment_id
    assignment_name = Assignment.find(attributes[:assignment_id]).short_identifier
    exam_template_name = attributes[:name].nil? ? File.basename(attributes[:filename].tr(' ', '_'), '.pdf') : attributes[:name]
    template_path = File.join(
      MarkusConfigurator.markus_exam_template_dir,
      assignment_name,
      exam_template_name
    )
    FileUtils.mkdir_p template_path unless Dir.exists? template_path

    File.open(File.join(template_path, attributes[:filename]), 'wb') do |f|
      f.write blob
    end

    pdf = CombinePDF.parse blob
    attributes[:num_pages] = pdf.pages.length

    create(attributes)
  end

  # Instantiate an ExamTemplate with the correct file
  def self.new_with_file(blob, attributes={})
    return unless attributes.has_key? :assignment_id
    assignment = Assignment.find(attributes[:assignment_id])
    assignment_name = assignment.short_identifier
    filename = attributes[:filename].tr(' ', '_')
    name_input = attributes[:name]
    exam_template_name = name_input == '' ? File.basename(attributes[:filename].tr(' ', '_'), '.pdf') : name_input
    template_path = File.join(
      MarkusConfigurator.markus_exam_template_dir,
      assignment_name,
      exam_template_name
    )
    FileUtils.mkdir_p template_path unless Dir.exists? template_path
    File.open(File.join(template_path, filename), 'wb') do |f|
      f.write blob
    end
    pdf = CombinePDF.parse blob
    num_pages = pdf.pages.length
    unless name_input == ''
      new_template = ExamTemplate.new(
        name: name_input,
        filename: filename,
        num_pages: num_pages,
        assignment: assignment
      )
    else
      new_template = ExamTemplate.new(
        filename: filename,
        num_pages: num_pages,
        assignment: assignment
      )
    end
    return new_template
  end

  # Replace an ExamTemplate with the correct file
  def replace_with_file(blob, attributes={})
    return unless attributes.has_key? :assignment_id
    assignment_name = Assignment.find(attributes[:assignment_id]).short_identifier
    template_path = File.join(
      MarkusConfigurator.markus_exam_template_dir,
      assignment_name,
      self.name
    )

    File.open(File.join(template_path, attributes[:new_filename].tr(' ', '_')), 'wb') do |f|
      f.write blob
    end

    pdf = CombinePDF.parse blob
    self.update(num_pages: pdf.pages.length, filename: attributes[:new_filename])
  end

  def delete_with_file
    FileUtils.rm_rf base_path
    self.destroy
  end

  # Generate copies of the given exam template, with the given start number.
  def generate_copies(num_copies, start=1)
    GenerateJob.perform_later(self, num_copies, start)
  end

  # Split up PDF file based on this exam template.
  def split_pdf(path, original_filename=nil, current_user=nil)
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
      user: current_user
    )

    raw_dir = File.join(self.base_path, 'raw')
    FileUtils.mkdir_p raw_dir
    FileUtils.cp path, File.join(raw_dir, "raw_upload_#{split_pdf_log.id}.pdf")

    SplitPDFJob.perform_later(self, path, split_pdf_log, original_filename, current_user)
  end

  def fix_error(filename, exam_num, page_num, upside_down)
    error_file = File.join(
      base_path, 'error', filename
    )
    return unless File.exists? error_file
    complete_dir = File.join(
      base_path, 'complete', exam_num
    )
    incomplete_dir = File.join(
      base_path, 'incomplete', exam_num
    )
    # if file is missing from complete group
    unless File.exists? File.join(complete_dir, page_num)
      # if there isn't corresponding file in incomplete group
      unless File.exists? File.join(incomplete_dir, page_num)
        # if incomplete directory doesn't exist yet
        FileUtils.mkdir_p incomplete_dir unless Dir.exists? incomplete_dir
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
          File.open(error_file_new_name, 'wb') do |f|
            f.write new_pdf.to_pdf
          end
        end

        # Update status of split_page to be FIXED
        split_page_id = File.basename(filename, '.pdf') # since filename is "#{split_page.id}.pdf"
        split_page = SplitPage.find(split_page_id)
        group = Group.find_or_create_by(
          group_name: "#{self.name}_paper_#{exam_num}",
          repo_name: "#{self.name}_paper_#{exam_num}"
        )
        split_page.update_attributes(status: 'FIXED', exam_page_number: page_num, group: group)
        # This creates both a new grouping and a new folder in the group repository
        # when a new group is entered.
        Grouping.find_or_create_by(
          group_id: group.id,
          assignment_id: self.assignment_id
        )

        # add assignment files based on template divisions
        repo = group.repo
        revision = repo.get_latest_revision
        assignment_folder = self.assignment.repository_folder
        txn = repo.get_transaction(Admin.first.user_name)
        self.template_divisions.each do |template_division|
          if template_division.start <= page_num.to_i && page_num.to_i <= template_division.end
            submission_file = CombinePDF.new
            (template_division.start..template_division.end).each do |i|
              path = File.join(incomplete_dir, "#{i}.pdf")
              if File.exists? path
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
        end

        # update COVER.pdf if error page given is first page of exam template
        if page_num.to_i == 1
          path = File.join(incomplete_dir, "#{page_num}.pdf")
          if File.exists? path
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
        if Dir.exists?(incomplete_dir)
          Dir.entries(incomplete_dir).sort.each do |filename|
            path = File.join(incomplete_dir, filename)
            basename = File.basename filename # For example, 3 from 3.pdf
            page_number = basename.to_i
            # if it is an extra page, add it to extra_pdf
            if File.exists?(path) && !filename.start_with?('.') &&
              template_divisions.all? { |division| division.start > page_number || division.end < page_number } && page_number != 1
              pdf = CombinePDF.load path
              extra_pdf << pdf.pages[0]
            end
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
    File.join MarkusConfigurator.markus_exam_template_dir,
              assignment.short_identifier, self.name
  end

  private

  # name and filename shouldn't include whitespace
  def set_formats_for_name_and_filename
    self.name = self.name.tr(' ', '_')
    self.filename = self.filename.tr(' ', '_')
  end

  def set_defaults_for_name
    # Attribute 'name' of exam template is by default set to filename without extension
    extension = File.extname self.filename
    basename = File.basename self.filename, extension
    self.name ||= basename
  end

  # when name of exam template is changed, exam template directory in server should be renamed
  def rename_exam_template_directory
    if self.name_changed?
      assignment_name = self.assignment.short_identifier
      old_directory_name = File.join(
        MarkusConfigurator.markus_exam_template_dir,
        assignment_name,
        name_was
      )
      new_directory_name = File.join(
        MarkusConfigurator.markus_exam_template_dir,
        assignment_name,
        name
      )
      File.rename old_directory_name, new_directory_name
    end
  end

  # any changes to template divisions should be rejected once exams have been uploaded
  def exam_been_uploaded?
    self.split_pdf_logs.any?
  end
end
