require 'fileutils'
require 'combine_pdf'
require 'prawn'
require 'prawn/qrcode'
require 'zxing'
require 'rmagick'

class ExamTemplate < ActiveRecord::Base
  before_save :set_formats_for_name_and_filename
  after_initialize :set_defaults_for_name, unless: :persisted? # will only work if the object is new
  belongs_to :assignment
  validates :assignment, :filename, :num_pages, :name, presence: true
  validates_uniqueness_of :name,
                          scope: :assignment
  validates :num_pages, numericality: { greater_than_or_equal_to: 0,
                                        only_integer: true }

  has_many :split_pdf_logs, dependent: :destroy
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
    GenerateJob.perform_later(self, num_copies, start)
  end

  # Split up PDF file based on this exam template.
  def split_pdf(path, original_filename=nil, current_user=nil)
    SplitPDFJob.perform_later(self, path, original_filename, current_user)
  end

  def fix_error(filename, exam_num, page_num)
    error_file = File.join(
      base_path, 'error', filename
    )
    complete_dir = File.join(
      base_path, 'complete', exam_num
    )
    # if file is missing from complete group
    unless File.exists?(File.join(complete_dir, page_num))
      incomplete_dir = File.join(
        base_path, exam_num, 'incomplete'
      )
      # move the file into incomplete group
      FileUtils.mv(error_file, incomplete_dir)
    end
  end

  def base_path
    File.join MarkusConfigurator.markus_exam_template_dir,
              assignment.short_identifier
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
end
