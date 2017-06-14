require 'fileutils'
require 'combine_pdf'
require 'prawn'
require 'prawn/qrcode'
require 'zxing'
require 'rmagick'

class ExamTemplate < ActiveRecord::Base
  after_initialize :set_defaults_for_name, unless: :persisted? # will only work if the object is new
  belongs_to :assignment
  validates :assignment, :filename, :num_pages, :name, presence: true
  validates :name, uniqueness: true
  validates :num_pages, numericality: { greater_than_or_equal_to: 0,
                                        only_integer: true }

  has_many :template_divisions, dependent: :destroy
  accepts_nested_attributes_for :template_divisions, allow_destroy: true, update_only: true

  # Create an ExamTemplate with the correct file
  def self.create_with_file(blob, attributes={})
    return unless attributes.has_key? :assignment_id
    assignment_name = Assignment.find(attributes[:assignment_id]).short_identifier
    template_path = File.join(
      MarkusConfigurator.markus_exam_template_dir,
      assignment_name
    )
    FileUtils.mkdir template_path unless Dir.exists? template_path

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
    filename = attributes[:filename]
    name_input = attributes[:name_input]
    template_path = File.join(
      MarkusConfigurator.markus_exam_template_dir,
      assignment_name
    )
    FileUtils.mkdir template_path unless Dir.exists? template_path
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
      assignment_name
    )

    File.open(File.join(template_path, attributes[:old_filename]), 'wb') do |f|
      f.write blob
    end

    pdf = CombinePDF.parse blob
    self.update(num_pages: pdf.pages.length, filename: attributes[:new_filename])
  end

  # Generate copies of the given exam template, with the given start number.
  def generate_copies(num_copies, start=1)
    GenerateJob.perform_now(self, num_copies, start)
  end

  # Split up PDF file based on this exam template.
  def split_pdf(path)
    SplitPDFJob.perform_now(self, path)
  end

  def base_path
    File.join MarkusConfigurator.markus_exam_template_dir,
              assignment.short_identifier
  end

  # Save the pages into groups for this assignment
  def save_pages(partial_exams)
    complete_dir = File.join(base_path, 'complete')
    incomplete_dir = File.join(base_path, 'incomplete')

    groupings = []
    partial_exams.each do |exam_num, pages|
      next if pages.empty?
      pages.sort_by! { |page_num, _| page_num }

      # Save raw pages
      if pages.length == num_pages
        destination = File.join complete_dir, "#{exam_num}"
      else
        destination = File.join incomplete_dir, "#{exam_num}"
      end
      FileUtils.mkdir_p destination unless Dir.exists? destination
      pages.each do |page_num, page|
        new_pdf = CombinePDF.new
        new_pdf << page
        new_pdf.save File.join(destination, "#{page_num}.pdf")
      end

      group = Group.find_or_create_by(
        group_name: group_name_for(exam_num),
        repo_name: group_name_for(exam_num)
      )

      groupings << Grouping.find_or_create_by(
        group: group,
        assignment: assignment
      )

      group.access_repo do |repo|
        assignment_folder = assignment.repository_folder
        txn = repo.get_transaction(Admin.first.user_name)


        # Pages that belong to a division
        template_divisions.each do |division|
          new_pdf = CombinePDF.new
          pages.each do |page_num, page|
            if division.start <= page_num && page_num <= division.end
              new_pdf << page
            end
          end
          txn.add(File.join(assignment_folder,
                            "#{division.label}.pdf"),
                  new_pdf.to_pdf,
                  'application/pdf'
          )
        end

        # Pages that don't belong to any division
        extra_pages = pages.reject do |page_num, _|
          template_divisions.any? do |division|
            division.start <= page_num && page_num <= division.end
          end
        end
        extra_pages.sort_by! { |page_num, _| page_num }
        extra_pdf = CombinePDF.new
        cover_pdf = CombinePDF.new
        start_page = 0
        if extra_pages[0][0] == 1
          cover_pdf << extra_pages[0][1]
          start_page = 1
        end
        extra_pdf << extra_pages[start_page..extra_pages.size].collect { |_, page| page }
        txn.add(File.join(assignment_folder,
                          "EXTRA.pdf"),
                extra_pdf.to_pdf,
                'application/pdf'
        )
        txn.add(File.join(assignment_folder,
                          "COVER.pdf"),
                cover_pdf.to_pdf,
                'application/pdf'
        )
        repo.commit(txn)
      end
    end
    SubmissionsJob.perform_now(groupings)
  end

  private

  def group_name_for(exam_num)
    "#{assignment.short_identifier}_paper_#{exam_num}"
  end

  def set_defaults_for_name
    # Attribute 'name' of exam template is by default set to filename without extension
    extension = File.extname self.filename
    basename = File.basename self.filename, extension
    self.name ||= basename
  end
end
