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
  belongs_to :autotest_setting, optional: true

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :name, format: { with: /\A[a-zA-Z0-9\-_]+\z/,
                             message: 'name must only contain alphanumeric, hyphen, or ' \
                                      'underscore' }

  # Note rails provides built-in sanitization via active record.
  validates :display_name, presence: true
  validates :is_hidden, inclusion: { in: [true, false] }

  # Returns an output file for controller to handle.
  def get_assignment_list(file_format)
    assignments = self.assignments
    case file_format
    when 'yml'
      map = {}
      map[:assignments] = assignments.map do |assignment|
        m = {}
        Assignment::DEFAULT_FIELDS.each do |f|
          m[f] = assignment.public_send(f)
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
        attrs.delete_if { |_, v| v.nil? }
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
            row[:submission_rule] = NoLateSubmissionRule.new
          end
          assignment.update(row)
          unless assignment.id
            assignment[:display_median_to_students] = false
            assignment[:display_grader_names_to_students] = false
          end
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

  def get_required_files
    assignments = self.assignments.includes(:assignment_files, :assignment_properties)
                      .where(assignment_properties: { scanned_exam: false }, is_hidden: false)
    required = {}
    assignments.each do |assignment|
      files = assignment.assignment_files.map(&:filename)
      if assignment.only_required_files.nil?
        required_only = false
      else
        required_only = assignment.only_required_files
      end
      required[assignment.repository_folder] = { required: files, required_only: required_only }
    end
    required
  end

  def max_file_size_settings
    Settings[self.name]&.max_file_size || Settings.max_file_size
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
    output = []
    students = self.students.joins(:user).order('users.user_name').includes(:section)
    students.each do |student|
      output.push(user_name: student.user_name,
                  last_name: student.last_name,
                  first_name: student.first_name,
                  email: student.email,
                  id_number: student.id_number,
                  section_name: student.section&.name)
    end
    output.to_yaml
  end
end
