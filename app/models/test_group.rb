class TestGroup < ApplicationRecord
  enum display_output: { instructors: 0, instructors_and_student_tests: 1, instructors_and_students: 2 },
       _prefix: :display_to

  belongs_to :assignment
  belongs_to :criterion, optional: true, polymorphic: true
  has_many :test_group_results, dependent: :delete_all

  # Run delete_file method after removal from db
  after_destroy :delete_file

  validates :name, presence: true, uniqueness: { scope: :assignment_id }
  validates :run_by_instructors, :run_by_students, inclusion: { in: [true, false] }
  validates :display_output, presence: true

  # All callback methods are protected methods
  protected

  # If replacing a file with a different name, delete the old file from MarkUs
  # before writing the new file
  def delete_old_file
    # Execute if the full file path exists (indicating a new File object)
    if @file_path
      # If the filenames are different, delete the old file
      if self.name_changed?
        # Delete old file
        self.delete_file
      end
    end
  end

  # Uploads the new file to the Automated Tests repository
  def write_file
    # Execute if the full file path exists (indicating a new File object)
    if @file_path
      name = self.name
      test_dir = File.join(AutomatedTestsClientHelper::ASSIGNMENTS_DIR, self.assignment.short_identifier)

      # Create the file path
      path = File.join(test_dir, name)

      # Read and write the file (overwrite if it exists)
      File.open(path, "w+") { |f| f.write(@file_path.read) }
    end
  end

  def delete_file
    file_path = File.join(AutomatedTestsClientHelper::ASSIGNMENTS_DIR, self.assignment.short_identifier, self.name)
    if File.exist?(file_path)
      File.delete(file_path)
    end
  end

end
