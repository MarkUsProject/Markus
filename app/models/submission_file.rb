class SubmissionFile < ApplicationRecord
  belongs_to :submission
  validates_associated :submission

  has_many :annotations

  has_one :course, through: :submission

  validates :filename, presence: true

  validates :path, presence: true

  validates :is_converted, inclusion: { in: [true, false] }

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
      retrieved_file = add_annotations(retrieved_file)
    end
    retrieved_file
  end

  private

  def add_annotations(file_contents)
    comment_syntax = FileHelper.get_comment_syntax(filename)
    result = ''
    file_contents.split("\n").each_with_index do |contents, index|
      annotations.each do |annot|
        if index == annot.line_start.to_i - 1
          annotation_text = AnnotationText.find(annot.annotation_text_id)
          text = annotation_text.content
          unless annotation_text.deduction.nil? || annotation_text.deduction == 0
            text += " [#{annotation_text.annotation_category.flexible_criterion.name}: -#{annotation_text.deduction}]"
          end
          result.concat(I18n.t('annotations.download_submission_file.begin_annotation',
                               id: annot.annotation_number.to_s,
                               text: text,
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
end
