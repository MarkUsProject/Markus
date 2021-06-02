# Helper for replacing unwanted characters in filenames.
module FileHelper
  # Only allow alphanumeric characters, '.', '-', and '_' as
  # character set for submission files.
  FILENAME_SANITIZATION_REGEXP = Regexp.new('[^0-9a-zA-Z\.\-_]').freeze
  # Character to be used as a replacement for all characters
  # matching the regular expression above
  SUBSTITUTION_CHAR = '_'.freeze

  def self.sanitize_file_name(file_name)
    # If file_name is blank, return the empty string
    return '' if file_name.nil?
    File.basename(file_name).gsub(
      FILENAME_SANITIZATION_REGEXP,
      SUBSTITUTION_CHAR
    )
  end

  def self.get_file_type(filename)
    # This is where you can add more languages that SubmissionFile will
    # recognize.  It will return the name of the language, which
    # SyntaxHighlighter can work with.
    case File.extname(filename).downcase
    when '.sci'
      'scilab'
    when '.java'
      'java'
    when '.rb'
      'ruby'
    when '.py'
      'python'
    when '.js'
      'javascript'
    when '.html'
      'html'
    when '.css'
      'css'
    when '.c', '.h', '.cpp'
      'c'
    when '.hs'
      'haskell'
    when '.scm', '.ss', '.rkt'
      'scheme'
    when '.tex', '.latex'
      'tex'
    when '.jpeg', '.jpg', '.gif', '.png', '.heic', '.heif'
      'image'
    when '.pdf'
      'pdf'
    when '.ipynb'
      'jupyter-notebook'
    else
      'unknown'
    end
  end

  def self.get_comment_syntax(filename)
    # This is where you can add more languages that SubmissionFile will
    # be able to insert comments into, for example when downloading annotations.
    # It will return a list, with the first element being the syntax to start a
    # comment and the second element being the syntax to end a comment.  Use
    #the language's multiple line comment format.
    case File.extname(filename)
    when '.java', '.js', '.c', '.css', '.h', '.cpp'
      %w[/* */]
    when '.rb'
      %w[=begin\n \n=end]
    when '.py'
      %w[""" """]
    when '.scm', '.ss', '.rkt'
      %w[#| |#]
    when '.hs'
      %w[{- -}]
    when '.html'
      %w[<!-- -->]
    else
      %w[## ##]
    end
  end
end
