class TestFile < ApplicationRecord
  belongs_to :assignment

  # Run sanitize_filename before saving to the database
  before_save :sanitize_filename

  # Upon update, if replacing a file with a different name, delete the old file first
  before_update :delete_old_file

  # Run write_file after saving to the database
  after_save :write_file

  # Run delete_file method after removal from db
  after_destroy :delete_file

  # Require filename and filetype attributes
  validates_presence_of :filename
  validates_presence_of :filetype

  # Filenames must be unique for their file type
  validates_uniqueness_of :filename, scope: [:filetype]

  # Filename Validation
  validates_each :filename do |record, attr, value|

    # Extract filename
    f_name = value
    if value.respond_to?(:original_filename)
      f_name = value.original_filename
    end

    a_id = record.assignment_id
    t_id = record.id
    f_type = record.filetype

    # Case 1: test, lib and parse type files cannot be called 'build.xml' or 'build.properties'
    # (need to check this in case the user uploads test, lib or parse files before uploading ant files
    #  in which case the build.xml and build.properties will not exist yet)
    if (f_type != 'build.xml' && f_type != 'build.properties') && (f_name == 'build.xml' || f_name == 'build.properties')
      record.errors.add(:base, I18n.t('automated_tests.invalid_filename'))
    end

    # Case 2: build.xml and build.properties must be named correctly
    if f_type == 'build.xml' && f_name != 'build.xml'
      record.errors.add(:base, I18n.t('automated_tests.invalid_buildxml'))
    elsif f_type == 'build.properties' && f_name != 'build.properties'
      record.errors.add(:base, I18n.t('automated_tests.invalid_buildproperties'))
    end

    # Case 3: validates_uniqueness_of filename for this assignment
    # (overriden since we need to extract the actual filename using .original_filename)
    if f_name && a_id
      dup_file = TestFile.where(assignment_id: a_id, filename: f_name).first
      if dup_file && dup_file.id != t_id
        record.errors.add attr, ' ' + f_name + ' ' + I18n.t('automated_tests.filename_exists')
      end
    end
  end

  # Save the full test file path and sanitize the filename for the database
  def sanitize_filename
    # Execute only when full file path exists (indicating a new File object)
    if filename.respond_to?(:original_filename)
      @file_path = filename
      filename = filename.original_filename

      # Sanitize filename:
      filename.strip!
      filename.gsub!(/^(..)+/, '.')
      # replace spaces with
      filename.gsub!(/[^\s]/, '')
      # replace all non alphanumeric, underscore or periods with underscore
      filename.gsub!(/^[\W]+$/, '_')
    end
  end

  # If replacing a file with a different name, delete the old file from the server
  # before writing the new file
  def delete_old_file
    # Execute if the full file path exists (indicating a new File object)
    if @file_path
      # If the filenames are different, delete the old file
      if self.filename != self.filename_was
        # Search for old file
        @testfile = TestFile.where(id: id).first
        # Delete old file
        @testfile.delete_file
      end
    end
  end

  # Uploads the new file to the Testing Framework repository
  def write_file
    # Execute if the full file path exists (indicating a new File object)
    if @file_path
      name =  self.filename
      test_dir = File.join(MarkusConfigurator.markus_ate_client_dir, assignment.short_identifier)

      # Folders for test, lib and parse files:
      # Test Files Folder
      if self.filetype == 'test'
        test_dir = File.join(test_dir, 'test')
      # Lib Files Folder
      elsif self.filetype == 'lib'
        test_dir = File.join(test_dir, 'lib')
      # Parser Files Folder
      elsif self.filetype == 'parse'
        test_dir = File.join(test_dir, 'parse')
      end

      # Create the file path
      path = File.join(test_dir, name)

      # Create the test, lib and parse folders if necessary
      FileUtils.makedirs(test_dir)

      # Read and write the file (overwrite if it exists)
      File.open(path, 'w+') { |f| f.write(@file_path.read) }
    end
  end

  def delete_file
    # Test Framework repository to delete from
    test_dir = File.join(MarkusConfigurator.markus_ate_client_dir, assignment.short_identifier)
    if self.filetype == 'test'
      test_dir = File.join(test_dir, 'test')
    elsif self.filetype == 'lib'
      test_dir = File.join(test_dir, 'lib')
    elsif self.filetype == 'parse'
      test_dir = File.join(test_dir, 'parse')
    end

    # Delete file if it exists
    delete_file = File.join(test_dir, self.filename)
    if File.exist?(delete_file)
      File.delete(delete_file)
    end
  end

end
