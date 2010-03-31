require 'machinist/active_record'
require 'sham'
require 'faker'

Sham.section_name {Faker::Name.name}

Sham.user_name {Faker::Name.name}
Sham.admin_user_name {|i| "admin#{i}"}
Sham.student_user_name {|i| "student#{i}"}
Sham.ta_user_name {|i| "ta#{i}"}
Sham.first_name {Faker::Name.first_name}
Sham.last_name {Faker::Name.last_name}

Sham.filename { "#{Faker::Lorem.words(1)[0]}.java"}
Sham.group_name {|i| "group#{i}"}

Sham.short_identifier {|i| "A#{i}"}
Sham.description {Faker::Lorem.sentence(2)}
Sham.message {Faker::Lorem.sentence(2)}
Sham.due_date {2.days.from_now}

Sham.notes_message {Faker::Lorem.paragraphs}

Sham.overall_comment {Faker::Lorem.sentence(3)}

Sham.flexible_criterion_name {|i| "flexible_criterion_#{i}"}
Sham.rubric_criterion_name {|i| "rubric_criterion_#{i}"}

Sham.date {2.days.from_now}
Sham.name {Faker::Name.name}

Admin.blueprint do
  type {'Admin'}
  user_name {Sham.admin_user_name}
  first_name
  last_name
end

Assignment.blueprint do
  short_identifier
  description
  message
  due_date
  group_min {2}
  group_max {4}
  student_form_groups {true}
  instructor_form_groups {false}
  repository_folder {"repo/#{short_identifier}"}
  marking_scheme_type {'rubric'}
  submission_rule {NoLateSubmissionRule.make({:assignment_id => object_id})}
  allow_web_submits {true}
end

AssignmentFile.blueprint do
  assignment
  filename
end

FlexibleCriterion.blueprint do
  flexible_criterion_name
  description
  position {1} # override if many for the same assignment
  max{10}
end

Grade.blueprint do
  grade_entry_item {GradeEntryItem.make}
  grade_entry_student {GradeEntryStudent.make}
  grade {0}
end

GracePeriodDeduction.blueprint do
  membership  {StudentMembership.make}
  deduction {20}
end

GradeEntryForm.blueprint do
  short_identifier
  description
  message
  date
end

GradeEntryItem.blueprint do
  grade_entry_form
  name
  out_of {10}
end

GradeEntryStudent.blueprint do
  grade_entry_form {GradeEntryForm.make}
  user {Student.make}
  released_to_student {false}
end

Group.blueprint do
  group_name
end

Grouping.blueprint do
  group
  assignment
end

Mark.blueprint do
  result
  markable {RubricCriterion.make}
  mark {Kernel::rand(4)}
end

Note.blueprint do
  noteable_type  {'Grouping'}
  noteable_id {Grouping.make.id}
  user {Admin.make}
  notes_message  {Faker::Lorem.paragraphs}
end

NoLateSubmissionRule.blueprint do
  assignment_id {0}
  type {'NoLateSubmissionRule'}
end

Result.blueprint do
  submission
  marking_state {'partial'}
  overall_comment
  released_to_students {false}
end

RubricCriterion.blueprint do
  rubric_criterion_name
  position {1} # override if many for the same assignment
  assignment
  weight {1}
end

Section.blueprint do
  name {Sham.section_name}
end

Student.blueprint do
  type {'Student'}
  user_name {Sham.student_user_name}
  first_name
  last_name
  section
  grace_credits {5}
end

Student.blueprint(:hidden) do
  hidden { true }
end

StudentMembership.blueprint do
  user {Student.make}
  grouping
  membership_status {StudentMembership::STATUSES[:pending]}
end

Submission.blueprint do 
  grouping
  submission_version {1}
  submission_version_used {true}
  revision_number {1}
  revision_timestamp {1.days.ago}
end

Ta.blueprint do
  type {'Ta'}
  user_name {Sham.ta_user_name}
  first_name
  last_name
end

TAMembership.blueprint do
  user {Ta.make}
  grouping
  membership_status {'pending'}
end

