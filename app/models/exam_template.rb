require 'combine_pdf'

class ExamTemplate < ActiveRecord::Base
  belongs_to :assignment
  validates :assignment, :filename, :num_pages, presence: true
  validates :num_pages, numericality: { greater_than_or_equal_to: 0,
                                        only_integer: true }

  has_many :template_divisions, dependent: :destroy

  # Create an ExamTemplate with the correct file
  def self.create_with_file(blob, attributes={})
    return unless attributes.has_key? :assignment_id
    assignment_name = Assignment.find(attributes[:assignment_id]).short_identifier
    template_path = File.join(
                          MarkusConfigurator.markus_exam_template_dir,
                          assignment_name
    )
    unless Dir.exist? template_path
      Dir.mkdir(template_path)
    end

    File.open(File.join(template_path, attributes[:filename]), 'wb') do |f|
      f.write blob
    end

    pdf = CombinePDF.parse blob
    attributes[:num_pages] = pdf.pages.length

    create(attributes)
  end
end
