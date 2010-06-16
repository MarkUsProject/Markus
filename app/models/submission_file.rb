
class SubmissionFile < ActiveRecord::Base
  
  belongs_to  :submission
  has_many :annotations
  validates_associated :submission
  validates_presence_of :submission
  validates_presence_of :filename
  validates_presence_of :path
  
  def get_file_type
    # This is where you can add more languages that SubmissionFile will
    # recognize.  It will return the name of the language, which
    # SyntaxHighlighter can work with.
    case File.extname(filename)
    when ".java"
      return "java"
    when ".rb"
      return "ruby"
    when ".py"
      return "python"
    when ".js"
      return "javascript"
    when ".c"
      return "c"
    when ".scm"
      return "scheme"
    when ".ss"
      return "scheme"
    else
      return "unknown"
    end
  end

  def is_supported_image?
    #Here you can add more image types to support
    supported_formats = ['.jpeg', '.jpg', '.gif', '.png']
    return supported_formats.include?(File.extname(filename))
  end


  # Taken from http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/44936
  def self.is_binary?(file_contents)
    return file_contents.size == 0 ||
          file_contents.count("^ -~", "^\r\n") / file_contents.size > 0.3 ||
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
    return unless self.is_supported_image?
    all_annotations = []
    self.annotations.each do |annot|
      if annot.is_a?(ImageAnnotation)
        extracted_coords = annot.extract_coords
        return nil if extracted_coords.nil?
        all_annotations.push(extracted_coords)
      end
    end
    return all_annotations
  end
end
