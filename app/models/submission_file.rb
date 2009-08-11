
class SubmissionFile < ActiveRecord::Base
  
  belongs_to  :submission
  has_many :annotations
  validates_associated :submission
  validates_presence_of :submission
  validates_presence_of :filename
  validates_presence_of :path
  
  def get_file_type
    #TODO:  Add more languages?
    case File.extname(filename)
    when ".java"
      return "java"
    when ".rb"
      return "ruby"
    when ".py"
      return "python"
    when ".js"
      return "javascript"
    else
      return "unknown"
    end
  end
  
  # Taken from http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/44936
  def self.is_binary?(file_contents)
    return file_contents.size == 0 ||
          file_contents.count("^ -~", "^\r\n") / file_contents.size > 0.3 ||
          file_contents.count("\x00") > 0
  end
  
end
