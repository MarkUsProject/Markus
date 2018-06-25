##############################################################
# This is the model for the database table test_scripts,
# which each instance of this model represents a test script
# file submitted by the admin. It can be written in any
# scripting language (bash script, ruby, python etc.). The
# admin uploads the test script and saves in some repository
# in MarkUs. When a user sends a test request, MarkUs executes
# all the test scripts of the assignment, in the order
# specified by seq_num. The test script can assume all the
# test support files are in the same file directory to help
# running the test.
#
# The attributes of test_scripts are:
#   assignment_id:      id of the assignment
#   seq_num:            a floating point number indicates the
#                       order of the execution. The test script
#                       with the smallest seq_num executes first.
#   file_name:          name of the script
#   description:        a brief description of the script. It
#                       can be shown to the students. (optionally)
#   run_by_instructors: a boolean indicates if this script will run
#                       when testing is initiated by admins and tas
#                       (e.g. after collection)
#   run_by_students:    a boolean indicates if this script will run
#                       when testing is initiated by students
#                       (e.g. on request)
#   halts_testing:      a boolean indicates if this script halts
#                       the test run when error occurs
#   display_description
#   display_run_status
#   display_marks_earned
#   display_input
#   display_expected_output
#   display_actual_output
#
#   The 6 attributes start with "display" have similar usages.
#   Each has a value of one of {"do_not_display",
#                               "display_after_submission",
#                               "display_after_collection"},
#   which indicates whether or not and when it is displayed
#   to the student.
##############################################################

class TestScript < ApplicationRecord
  belongs_to :assignment
  has_many :test_script_results, dependent: :delete_all
  belongs_to :criterion, optional: true, polymorphic: true

  # Run sanitize_filename before saving to the database
  before_save :sanitize_filename

  # Run delete_file method after removal from db
  after_destroy :delete_file

  validates_associated :assignment

  validates_presence_of :seq_num
  validates_presence_of :file_name
  # TODO: validation fails if description is the empty string
  validates_presence_of :description, if: ->(o) { o.description.nil? }

  # validates the uniqueness of file_name for the same assignment
  validates_each :file_name do |record, attr, value|
    # Extract file_name
    name = value
    if value.respond_to?(:original_filename)
      name = value.original_filename
    end

    # FIXME: create a loop to loop through all dup_file
    # dup_files = TestScript.find_all_by_assignment_id_and_file_name(record.assignment_id, name)
    dup_file = TestScript.find_by(assignment_id: record.assignment_id, file_name: name)
    if dup_file && dup_file.id != record.id
      record.errors.add attr, ' ' + name + ' ' + I18n.t("automated_tests.filename_exists")
    end
  end

  validates_numericality_of :seq_num
  validates_numericality_of :timeout, only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 3600

  validates_presence_of :display_description
  validates_presence_of :display_run_status
  validates_presence_of :display_marks_earned
  validates_presence_of :display_input
  validates_presence_of :display_expected_output
  validates_presence_of :display_actual_output

  display_option = %w(do_not_display display_after_submission display_after_collection)
  validates_inclusion_of :display_description, in: display_option
  validates_inclusion_of :display_run_status, in: display_option
  validates_inclusion_of :display_input, in: display_option
  validates_inclusion_of :display_marks_earned, in: display_option
  validates_inclusion_of :display_expected_output, in: display_option
  validates_inclusion_of :display_actual_output, in: display_option

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
      test_dir = File.join(AutomatedTestsClientHelper::ASSIGNMENTS_DIR, assignment.short_identifier)

      # Create the file path
      path = File.join(test_dir, name)

      # Read and write the file (overwrite if it exists)
      File.open(path, "w+") { |f| f.write(@file_path.read) }
    end
  end

  def delete_file
    # Automated tests repository to delete from
    test_dir = File.join(AutomatedTestsClientHelper::ASSIGNMENTS_DIR, assignment.short_identifier)

    # Delete file if it exists
    path = File.join(test_dir, self.file_name)
    if File.exist?(path)
      File.delete(path)
    end
  end

end
