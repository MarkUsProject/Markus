##############################################################
# This is the model for the database table test_support_files,
# which each instance of this model represents a test support
# file submitted by the admin. It can be an input description
# of a test, an expected output of a test, a code library for
# testing, or any other file to support the test scripts for
# testing. MarkUs does not interpret a test support file.
#
# The attributes of test_support_files are:
#   file_name:      name of the support file. 
#   assignment_id:  id of the assignment
#   description:    a brief description of the purpose of the
#                   file.
#############################################################

class TestSupportFile < ActiveRecord::Base
  belongs_to :assignment
  
  # Run sanitize_filename before saving to the database
  before_save :sanitize_filename
  
  # Upon update, if replacing a file with a different name, delete the old file first
  before_update :delete_old_file
  
  # Run write_file after saving to the database
  after_save :write_file
  
  # Run delete_file method after removal from db
  after_destroy :delete_file
  
  validates_presence_of :assignment
  validates_associated :assignment
  
  validates_presence_of :file_name
  validates_presence_of :description, if: "description.nil?"
  
  # validates the uniqueness of file_name for the same assignment
  validates_each :file_name do |record, attr, value|
    # Extract file_name
    name = value
    if value.respond_to?(:original_filename)
      name = value.original_filename
    end

    dup_file = TestSupportFile.find_by_assignment_id_and_file_name(record.assignment_id, name)
    if dup_file && dup_file.id != record.id
      record.errors.add attr, ' ' + name + ' ' + I18n.t("automated_tests.filename_exists")
    end
  end
  
  # All callback methods are protected methods
  protected
  
  # Save the full test file path and sanitize the filename for the database
  def sanitize_filename
    # Execute only when full file path exists (indicating a new File object)
    if self.file_name.respond_to?(:original_filename)
      @file_path = self.file_name
      self.file_name = self.file_name.original_filename

      # Sanitize filename:
      self.file_name.strip!
      self.file_name.gsub(/^(..)+/, ".")
      # replace spaces with
      self.file_name.gsub(/[^\s]/, "")
      # replace all non alphanumeric, underscore or periods with underscore
      self.file_name.gsub(/^[\W]+$/, '_')
    end
  end

  # If replacing a file with a different name, delete the old file from MarkUs
  # before writing the new file
  def delete_old_file
    # Execute if the full file path exists (indicating a new File object)
    if @file_path
      # If the filenames are different, delete the old file
      if self.file_name_changed?
        # Delete old file
        self.delete_file
      end
    end
  end

  # Uploads the new file to the Automated Tests repository
  def write_file
    # Execute if the full file path exists (indicating a new File object)
    if @file_path
      name = self.file_name
      test_dir = File.join(MarkusConfigurator.markus_ate_client_dir, assignment.short_identifier)

      # Create the file path
      path = File.join(test_dir, name)

      # Read and write the file (overwrite if it exists)
      File.open(path, "w+") { |f| f.write(@file_path.read) }
    end
  end

  def delete_file
    # Automated tests repository to delete from
    test_dir = File.join(MarkusConfigurator.markus_ate_client_dir, assignment.short_identifier)

    # Delete file if it exists
    path = File.join(test_dir, self.file_name)
    if File.exist?(path)
      File.delete(path)
    end
  end

end
