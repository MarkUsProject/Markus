#!/usr/bin/env ruby

require 'active_record'
require 'erb'

ROLE_QUERY = %(
  SELECT roles.id, roles.type FROM users
  JOIN roles ON roles.user_id=users.id
  JOIN courses ON roles.course_id=courses.id
  WHERE courses.name=$1 AND users.user_name=$2
).freeze

TA_QUERY = %(
  SELECT roles.id FROM memberships
  JOIN roles ON roles.id=memberships.role_id
  JOIN groupings ON memberships.grouping_id=groupings.id
  JOIN groups ON groupings.group_id=groups.id
  JOIN assignment_properties ON assignment_properties.assessment_id=groupings.assessment_id
  WHERE memberships.type='TaMembership'
    AND assignment_properties.anonymize_groups=false
    AND roles.id=$1
    AND groups.repo_name=$2
).freeze

STUDENT_QUERY = %(
  SELECT roles.id FROM memberships
  JOIN roles ON roles.id=memberships.role_id
  JOIN groupings ON memberships.grouping_id=groupings.id
  JOIN groups ON groupings.group_id=groups.id
  JOIN assignment_properties ON assignment_properties.assessment_id=groupings.assessment_id
  JOIN assessments ON groupings.assessment_id=assessments.id
  LEFT OUTER JOIN assessment_section_properties ON assessment_section_properties.assessment_id=assessments.id
  WHERE memberships.type='StudentMembership'
    AND assignment_properties.vcs_submit=true
    AND roles.id=$1
    AND groups.repo_name=$2
    AND ((assessment_section_properties.is_hidden IS NULL AND assessments.is_hidden=false)
            OR assessment_section_properties.is_hidden=false)
    AND (assignment_properties.is_timed=false
            OR groupings.start_time IS NOT NULL
            OR (groupings.start_time IS NULL AND assessments.due_date<NOW()))
).freeze

begin
  rails_env = ENV.fetch('RAILS_ENV', 'development')
  user_name, repo_path = ARGV

  raise 'no repository path given' unless repo_path
  raise 'no user name given' unless user_name

  course_name = File.dirname(repo_path)
  repo_name = File.basename(repo_path, '.git')

  raise 'repository path does not include course directory' if course_name == '.'

  db_config_file = File.join(File.dirname(__dir__), 'config', 'database.yml')
  db_config = YAML.safe_load ERB.new(File.read(db_config_file)).result, aliases: true
  db_settings = db_config[rails_env]

  ActiveRecord::Base.establish_connection(db_settings)

  db_connection = ActiveRecord::Base.connection

  role = db_connection.exec_query(ROLE_QUERY,
                                  'SQL',
                                  [ActiveRecord::Relation::QueryAttribute.new(nil, course_name,
                                                                              ActiveRecord::Type::String.new),
                                   ActiveRecord::Relation::QueryAttribute.new(nil, user_name,
                                                                              ActiveRecord::Type::String.new)],
                                  prepare: true)

  case role.first&.[] 'type'
  when 'Instructor'
    exit(0)
  when 'Ta'
    ta = db_connection.exec_query(TA_QUERY,
                                  'SQL',
                                  [ActiveRecord::Relation::QueryAttribute.new(nil, role.first&.[]('id'),
                                                                              ActiveRecord::Type::Integer.new),
                                   ActiveRecord::Relation::QueryAttribute.new(nil, repo_name,
                                                                              ActiveRecord::Type::String.new)],
                                  prepare: true)
    exit(0) if ta.first&.[]('id')
  when 'Student'
    student = db_connection.exec_query(STUDENT_QUERY,
                                       'SQL',
                                       [ActiveRecord::Relation::QueryAttribute.new(nil, role.first&.[]('id'),
                                                                                   ActiveRecord::Type::Integer.new),
                                        ActiveRecord::Relation::QueryAttribute.new(nil, repo_name,
                                                                                   ActiveRecord::Type::String.new)],
                                       prepare: true)
    exit(0) if student.first&.[]('id')
  else
    raise 'user not found'
  end
  exit(1)
rescue StandardError => e
  warn e.message
  exit(1)
end
