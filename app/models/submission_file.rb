# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: submission_files
#
#  id               :integer          not null, primary key
#  error_converting :boolean          default(FALSE), not null
#  filename         :string           not null
#  is_converted     :boolean          default(FALSE), not null
#  path             :string           default("/"), not null
#  created_at       :datetime
#  updated_at       :datetime
#  submission_id    :integer          not null
#
# Indexes
#
#  index_submission_files_on_filename       (filename)
#  index_submission_files_on_submission_id  (submission_id)
#
# Foreign Keys
#
#  fk_submission_files_submissions  (submission_id => submissions.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class SubmissionFile < ApplicationRecord
  belongs_to :submission
  validates_associated :submission

  has_many :annotations

  has_one :course, through: :submission

  validates :filename, presence: true

  validates :path, presence: true

  validates :is_converted, inclusion: { in: [true, false] }
  validates :error_converting, inclusion: { in: [true, false] }

  def is_supported_image?
    # Here you can add more image types to support
    supported_formats = %w[.jpeg .jpg .gif .png .heic .heif]
    supported_formats.include?(File.extname(filename).downcase)
  end

  def is_pdf?
    File.extname(filename).casecmp('.pdf') == 0
  end

  def is_pynb?
    File.extname(filename).casecmp('.ipynb')&.zero?
  end

  def is_rmd?
    File.extname(filename).casecmp('.rmd')&.zero?
  end

  # The annotation class (single-table-inheritance subclass) appropriate for this file,
  # derived from its type. Mirrors the logic used when creating annotations in the UI
  # (see AnnotationsController), and is the single source of truth for that mapping.
  def annotation_class
    return ImageAnnotation if is_supported_image?
    return PdfAnnotation if is_pdf?
    return HtmlAnnotation if is_pynb? || (is_rmd? && Rails.application.config.rmd_convert_enabled)

    TextAnnotation
  end

  # Taken from http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/44936
  def self.is_binary?(file_contents)
    file_contents.size == 0 ||
          file_contents.count('^ -~', "^\r\n") / file_contents.size > 0.3 ||
          file_contents.count("\x00") > 0
  end

  # Return an array representing the annotated areas of the submission file
  #
  # ===Returns:
  #
  # An array containing the extracted coordinates of all the annotations
  # associated with this file
  #
  # Return nil if this SubmissionFile is not a supported image.

  def get_annotation_grid
    return unless self.is_supported_image? || self.is_pdf?
    all_annotations = []
    self.annotations.each do |annot|
      if annot.is_a?(ImageAnnotation)
        extracted_coords = annot.extract_coords
        return nil if extracted_coords.nil?
        all_annotations.push(extracted_coords)
      end
    end
    all_annotations
  end

  # Return the contents of this SubmissionFile. Include annotations in the
  # file if include_annotations is true.
  def retrieve_file(include_annotations: false, repo: nil)
    student_grouping = self.submission.grouping
    student_group = student_grouping.group
    revision_identifier = self.submission.revision_identifier

    get_retrieved_file = ->(open_repo) do
      revision = open_repo.get_revision(revision_identifier)
      revision_file = revision.files_at_path(self.path, with_attrs: false)[self.filename]
      if revision_file.nil?
        raise I18n.t('submissions.errors.could_not_find_file',
                     filename: self.filename,
                     group_name: student_group.group_name)
      end
      open_repo.download_as_string(revision_file)
    end

    if repo.nil?
      retrieved_file = student_grouping.access_repo do |open_repo|
        get_retrieved_file.call(open_repo)
      end
    else
      retrieved_file = get_retrieved_file.call(repo)
    end
    if include_annotations
      retrieved_file = is_pdf? ? add_pdf_annotations(retrieved_file) : add_annotations(retrieved_file)
    end
    retrieved_file
  end

  # The size, in PDF points, of the square that a PDF sticky note is anchored in.
  PDF_ANNOTATION_ICON_SIZE = 20

  private

  def add_annotations(file_contents)
    comment_syntax = FileHelper.get_comment_syntax(filename)
    result = ''
    file_contents.split("\n").each_with_index do |contents, index|
      annotations.each do |annot|
        if index == annot.line_start.to_i - 1
          result.concat(I18n.t('annotations.download_submission_file.begin_annotation',
                               id: annot.annotation_number.to_s,
                               text: annotation_content(annot),
                               comment_start: comment_syntax[0],
                               comment_end: comment_syntax[1]) + "\n")
        elsif index == annot.line_end.to_i
          result.concat(I18n.t('annotations.download_submission_file.end_annotation',
                               id: annot.annotation_number.to_s,
                               comment_start: comment_syntax[0],
                               comment_end: comment_syntax[1]) + "\n")
        end
      end
      result.concat(contents + "\n")
    end
    result
  end

  # Return the text of +annotation+ as it should appear in a downloaded file, including
  # the criterion deduction if the annotation carries one.
  def annotation_content(annotation)
    annotation_text = annotation.annotation_text
    content = annotation_text.content.to_s
    return content if [nil, 0].include?(annotation_text.deduction)

    "#{content} [#{annotation_text.annotation_category.flexible_criterion.name}: " \
      "-#{annotation_text.deduction}]"
  end

  # Return +file_contents+ (the contents of a PDF submission file) with this file's
  # annotations added as PDF "sticky note" annotations, so that they are visible at the
  # right location when the downloaded file is opened in a PDF viewer.
  def add_pdf_annotations(file_contents)
    annotations_by_page = annotations.where.not(page: nil)
                                     .order(:annotation_number)
                                     .includes(annotation_text: { annotation_category: :flexible_criterion })
                                     .group_by(&:page)
    return file_contents if annotations_by_page.empty?

    pdf = CombinePDF.parse(file_contents)
    # Prawn cannot modify an existing PDF, so the sticky notes are created in a separate,
    # otherwise empty, document with one page per page of the submission file.
    notes = Prawn::Document.new(skip_page_creation: true) do |doc|
      pdf.pages.each_with_index do |page, index|
        doc.start_new_page
        annotations_by_page.fetch(index + 1, []).each do |annotation|
          doc.text_annotation(pdf_annotation_rect(page, annotation),
                              "#{annotation.annotation_number}. #{annotation_content(annotation)}",
                              Name: :Comment, Open: false)
        end
      end
    end

    # CombinePDF drops annotations when injecting one page into another, so the :Annots
    # entries are copied over directly instead.
    pdf.pages.zip(CombinePDF.parse(notes.render).pages) do |page, notes_page|
      next if notes_page[:Annots].blank?
      existing = page[:Annots]
      existing = existing[:referenced_object] if existing.is_a?(Hash)
      page[:Annots] = (existing.is_a?(Array) ? existing : []) + notes_page[:Annots]
    end
    pdf.to_pdf
  end

  # Return the rectangle, in the PDF user space of +page+, that +annotation+'s sticky note
  # should be anchored to. Annotation coordinates are stored as a fraction (scaled by 1e5)
  # of the page as it is displayed, measured from its top left corner, so they need to be
  # scaled and flipped, and rotated back into user space if the page carries a :Rotate entry.
  def pdf_annotation_rect(page, annotation)
    left, bottom, right, top = page.page_size.map(&:to_f)
    rotation = page[:Rotate].to_i % 360
    sideways = [90, 270].include?(rotation)
    # (x, y) is the annotation's top left corner, in points from the displayed page's top left corner
    x = [annotation.x1, annotation.x2].min / 1.0e5 * (sideways ? top - bottom : right - left)
    y = [annotation.y1, annotation.y2].min / 1.0e5 * (sideways ? right - left : top - bottom)
    centre_x, centre_y = case rotation
                         when 90 then [left + y, bottom + x]
                         when 180 then [right - x, bottom + y]
                         when 270 then [right - y, top - x]
                         else [left + x, top - y]
                         end
    offset = PDF_ANNOTATION_ICON_SIZE / 2.0
    [centre_x - offset, centre_y - offset, centre_x + offset, centre_y + offset]
  end
end
