# Helper for replacing unwanted characters in filenames.
module FileHelper
  # Only allow alphanumeric characters, '.', '-', and '_' as
  # character set for submission files.
  FILENAME_SANITIZATION_REGEXP = Regexp.new('[^0-9a-zA-Z\.\-_\s]').freeze
  # Character to be used as a replacement for all characters
  # matching the regular expression above
  SUBSTITUTION_CHAR = '_'.freeze

  EXT_TO_TYPE = { '.sci' => 'scilab',
                  '.java' => 'java',
                  '.rb' => 'ruby',
                  '.py' => 'python',
                  '.js' => 'javascript',
                  '.jsx' => 'jsx',
                  '.html' => 'html',
                  '.css' => 'css',
                  '.c' => 'c',
                  '.h' => 'c',
                  '.cpp' => 'cpp',
                  '.hs' => 'haskell',
                  '.scm' => 'scheme',
                  '.ss' => 'scheme',
                  '.rkt' => 'racket',
                  '.tex' => 'tex',
                  '.jpeg' => 'image',
                  '.jpg' => 'image',
                  '.gif' => 'image',
                  '.png' => 'image',
                  '.heic' => 'image',
                  '.heif' => 'image',
                  '.latex' => 'tex',
                  '.pdf' => 'pdf',
                  '.ipynb' => 'jupyter-notebook',
                  '.r' => 'r',
                  '.rmd' => 'rmarkdown',
                  '.md' => 'markdown',
                  '.sql' => 'sql',
                  '.csv' => 'csv',
                  '.json' => 'json',
                  '.sh' => 'sh',
                  '.cmake' => 'cmake',
                  '.make' => 'makefile',
                  '.markusurl' => 'markusurl',
                  '.bin' => 'binary',
                  '.dat' => 'binary',
                  '.doc' => 'binary',
                  '.docx' => 'binary',
                  '.xls' => 'binary',
                  '.xlsx' => 'binary',
                  '.ppt' => 'binary',
                  '.pptx' => 'binary' }.freeze

  COMMENT_TO_SYNTAX = { '.java' => %w[/* */],
                        '.js' => %w[/* */],
                        '.c' => %w[/* */],
                        '.css' => %w[/* */],
                        '.h' => %w[/* */],
                        '.cpp' => %w[/* */], '.rb' => %W[=begin\n \n=end],
                        '.py' => %w[""" """],
                        '.scm' => %w[#| |#],
                        '.ss' => %w[#| |#],
                        '.rkt' => %w[#| |#],
                        '.hs' => %w[{- -}],
                        '.html' => %w[<!-- -->] }.freeze

  def self.sanitize_file_name(file_name)
    # If file_name is blank, return the empty string
    return '' if file_name.nil?
    File.basename(file_name).gsub(
      FILENAME_SANITIZATION_REGEXP,
      SUBSTITUTION_CHAR
    )
  end

  # Return a file type based on the extension of +filename+. Used for syntax highlighting.
  def self.get_file_type(filename)
    extension = File.extname(filename).downcase
    if EXT_TO_TYPE.key?(extension)
      EXT_TO_TYPE[extension]
    else
      'unknown'
    end
  end

  def self.get_comment_syntax(filename)
    # This is where you can add more languages that SubmissionFile will
    # be able to insert comments into, for example when downloading annotations.
    # It will return a list, with the first element being the syntax to start a
    # comment and the second element being the syntax to end a comment.  Use
    # the language's multiple line comment format.
    extension = File.extname(filename).downcase
    if COMMENT_TO_SYNTAX.key?(extension)
      COMMENT_TO_SYNTAX[extension]
    else
      %w[## ##]
    end
  end

  # Join +path+ and +paths+, where +paths+ are potentially untrusted inputs.
  # Returns +nil+ if the resulting path is outside +path+.
  def self.checked_join(path, *paths)
    new_path = File.join(path, *paths)
    if File.expand_path(new_path).start_with?(File.expand_path(path))
      new_path
    end
  end
end
