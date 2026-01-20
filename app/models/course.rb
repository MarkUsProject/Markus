# Class describing a course
class Course < ApplicationRecord
  has_many :assessments, inverse_of: :course, dependent: :destroy
  has_many :assignments
  has_many :grade_entry_forms
  has_many :sections, inverse_of: :course
  has_many :groups, inverse_of: :course
  has_many :roles
  has_many :instructors
  has_many :tas
  has_many :students
  has_many :marking_schemes
  has_many :tags, through: :roles
  has_many :exam_templates, through: :assignments
  has_many :lti_deployments
  belongs_to :autotest_setting, optional: true

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :name, format: { with: /\A[a-zA-Z0-9\-_]+\z/ }

  # Note rails provides built-in sanitization via active record.
  validates :display_name, presence: true
  validates :is_hidden, inclusion: { in: [true, false] }
  validates :max_file_size, numericality: { greater_than_or_equal_to: 0 }

  after_save_commit :update_repo_max_file_size
  after_update_commit :update_repo_permissions

  # Returns an output file for controller to handle.
  def get_assignment_list(file_format)
    assignments = self.assignments
    case file_format
    when 'yml'
      map = {}
      map[:assignments] = assignments.map do |assignment|
        m = {}
        # Add assessment fields (root level)
        Assignment::ASSESSMENT_FIELDS.each do |f|
          m[f] = assignment.public_send(f)
        end
        # Add assignment_properties fields (nested)
        m[:assignment_properties_attributes] = {}
        Assignment::ASSIGNMENT_PROPERTIES_FIELDS.each do |f|
          m[:assignment_properties_attributes][f] = assignment.public_send(f)
        end
        m
      end
      map.to_yaml
    when 'csv'
      MarkusCsv.generate(assignments) do |assignment|
        Assignment::DEFAULT_FIELDS.map do |f|
          assignment.public_send(f)
        end
      end
    end
  end

  def upload_assignment_list(file_format, assignment_data)
    case file_format
    when 'csv'
      MarkusCsv.parse(assignment_data) do |row|
        assignment = self.assignments.find_or_create_by(short_identifier: row[0])
        attrs = Assignment::DEFAULT_FIELDS.zip(row).to_h
        attrs.compact!
        if assignment.new_record?
          assignment.assignment_properties.repository_folder = row[0]
          assignment.assignment_properties.token_period = 1
          assignment.assignment_properties.unlimited_tokens = false
        end
        assignment.update(attrs)
        raise CsvInvalidLineError unless assignment.valid?
      end

    when 'yml'
      begin
        map = assignment_data.deep_symbolize_keys
        map[:assignments].map do |row|
          assignment = self.assignments.find_or_create_by(short_identifier: row[:short_identifier])
          if assignment.new_record?
            row[:assignment_properties_attributes] = {}
            row[:assignment_properties_attributes][:repository_folder] = row[:short_identifier]
            row[:assignment_properties_attributes][:token_period] = 1
            row[:assignment_properties_attributes][:unlimited_tokens] = false
          end
          assignment.update(row)
        end
      rescue ActiveRecord::ActiveRecordError, ArgumentError => e
        e
      end
    end
  end

  # start showing (or "featuring") the assignment 3 days before it's due
  def get_current_assignment
    self.assignments.where(due_date: ..3.days.from_now).reorder(due_date: :desc).first ||
        self.assignments.reorder(:due_date).first
  end

  # Return a string where each line contains a required file for this course and a boolean string ('true' or 'false')
  # indicating whether the assignment this required file belongs to has the only_required_files attribute set to true
  # of false. For example:
  #
  # A0/submission.py true
  # A0/submission2.py true
  # A0/data.txt true
  # A5/something.hs false
  def get_required_files
    assignments = self.assignments.includes(:assignment_files, :assignment_properties)
                      .where(assignment_properties: { scanned_exam: false }, is_hidden: false)
    assignments.flat_map do |assignment|
      assignment.assignment_files.map do |file|
        filename = File.join(assignment.repository_folder, file.filename)
        "#{filename} #{assignment.only_required_files ? true : false}"
      end
    end.join("\n")
  end

  def export_student_data_csv
    students = self.students.joins(:user).order('users.user_name').includes(:section)
    MarkusCsv.generate(students) do |student|
      Student::CSV_ORDER.map do |field|
        if field == :section_name
          student.section&.name
        else
          student.public_send(field)
        end
      end
    end
  end

  def export_student_data_yml
    students = self.students.joins(:user).order('users.user_name').includes(:section)
    output = students.map do |student|
      { user_name: student.user_name,
        last_name: student.last_name,
        first_name: student.first_name,
        email: student.email,
        id_number: student.id_number,
        section_name: student.section&.name }
    end
    output.to_yaml
  end

  # Yield an open repo for each group of this course, then yield again for each repo that raised an exception, to
  # try to mitigate concurrent accesses to those repos.
  def each_group_repo(&block)
    failed_groups = []
    self.groups.each do |group|
      group.access_repo(&block)
    rescue StandardError
      # in the event of a concurrent repo modification, retry later
      failed_groups << group
    end
    failed_groups.each do |grouping|
      grouping.access_repo(&block)
    rescue StandardError
      # give up
    end
  end

  private

  def update_repo_max_file_size
    return unless Settings.repository.type == 'git'
    return unless saved_change_to_max_file_size? || saved_change_to_id?

    UpdateRepoMaxFileSizeJob.perform_later(self.id)
  end

  def update_repo_permissions
    Repository.get_class.update_permissions if saved_change_to_is_hidden?
  end
end
