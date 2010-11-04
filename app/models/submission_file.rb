class SubmissionFile < ActiveRecord::Base
  
  belongs_to  :submission
  has_many :annotations
  validates_associated :submission
  validates_presence_of :submission
  validates_presence_of :filename
  validates_presence_of :path
  
  validates_inclusion_of :is_converted, :in => [true, false]
  
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

    def get_comment_syntax
    # This is where you can add more languages that SubmissionFile will
    # be able to insert comments into, for example when downloading annotations.
    # It will return a list, with the first element being the syntax to start a
    # comment and the second element being the syntax to end a comment.  Use
    #the language's multiple line comment format.
    case File.extname(filename)
    when ".java", ".js", ".c"
      return ["/*", "*/"]
    when ".rb"
      return ["=begin\n", "\n=end"]
    when ".py"
      return ['"""', '"""']
    when ".scm", ".ss"
      return ["#|","|#"]
    else
      return ["##","##"]
    end
  end

  def is_supported_image?
    #Here you can add more image types to support
    supported_formats = ['.jpeg', '.jpg', '.gif', '.png']
    return supported_formats.include?(File.extname(filename))
  end

  def is_pdf?
    return File.extname(filename) == '.pdf'
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
    return unless self.is_supported_image? || self.is_pdf?
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
  
  def convert_pdf_to_jpg
    return unless MarkusConfigurator.markus_config_pdf_support && self.is_pdf?
    m_logger = MarkusLogger.instance
    storage_path = File.join(MarkusConfigurator.markus_config_pdf_storage,
      self.submission.grouping.group.repository_name, self.path)
    file_path = File.join(storage_path, self.filename.split('.')[0] + '.jpg')
    self.export_file(storage_path)
    #Remove any old copies of this image if they exist
    FileUtils.remove_file(file_path, true) if File.exists?(file_path)

    m_logger.log("Starting pdf conversion")
    # ImageMagick can only save images with heights not exceeding 65500 pixels.
    # Larger images result in a conversion failure.
    begin
      #This is an ImageMagick command, see http://www.imagemagick.org/script/convert.php for documentation
      `convert -limit memory #{MarkusConfigurator.markus_config_pdf_conv_memory_allowance} -limit map 0 -density 150 -resize 66% #{storage_path}/#{self.filename} -append #{file_path}`
      m_logger.log("Successfully converted pdf file to jpg")
    rescue Exception => e
      m_logger.log("Pdf file couldn't be converted")
    end

    FileUtils.remove_file(File.join(storage_path, self.filename), true)
    self.is_converted = true
    self.save
  end

  # Return the contents of this SubmissionFile.  Include annotations in the
  # file if include_annotations is true.
  def retrieve_file(include_annotations = false)
    student_group = submission.grouping.group
    repo = student_group.repo
    revision_number = submission.revision_number
    revision = repo.get_revision(revision_number)
    if revision.files_at_path(path)[filename].nil?
      raise I18n.t("results.could_not_find_file", :filename => filename,
        :repository_name => student_group.repository_name)
    end
    retrieved_file = repo.download_as_string(revision.files_at_path(path)[filename])
    repo.close
    if include_annotations
      retrieved_file = add_annotations(retrieved_file)
    end
    return retrieved_file
  end

  #Export this file from the svn repository into storage_path
  #This will overwrite any files with the same name in the storage path.
  def export_file(storage_path)
    m_logger = MarkusLogger.instance
    m_logger.log("Exporting #{self.filename} from student repository")
    temp_dir = File.join(storage_path, 'temp_export')
    begin
      #Create the storage directories if they dont already exist
      FileUtils.makedirs(storage_path)
      repo = submission.grouping.group.repo
      revision_number = submission.revision_number
      repo.export(temp_dir, revision_number)
      file_path = File.join(temp_dir, self.path, self.filename)
      FileUtils.mv(file_path, File.join(storage_path, self.filename), :force => true)
    ensure
      FileUtils.remove_dir(temp_dir, true) if File.exists?(temp_dir)      
    end
    m_logger.log("Successfuly exported #{self.filename} from student repository")
  end

  private

  def add_annotations(file_contents)
    comment_syntax = get_comment_syntax
    result = ""
    file_contents.split("\n").each_with_index do |contents, index|
      annotations.each do |annot|
        if index == annot.line_start.to_i - 1
           text = AnnotationText.find(annot.annotation_text_id).content
           result = result.concat(I18n.t("graders.download.begin_annotation", 
               :id => annot.annotation_number.to_s,
               :text => text,
               :comment_start => comment_syntax[0],
               :comment_end => comment_syntax[1]) + "\n")
        elsif index == annot.line_end.to_i
           result = result.concat(I18n.t("graders.download.end_annotation",
               :id => annot.annotation_number.to_s,
               :comment_start => comment_syntax[0],
               :comment_end => comment_syntax[1]) + "\n")
        end
      end
    result = result.concat(contents + "\n")
    end
    return result
  end
end

