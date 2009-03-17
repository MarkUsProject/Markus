
class SubmissionFile < ActiveRecord::Base
  
  belongs_to  :submission
  belongs_to  :user
  
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
    end
  end
  
end
