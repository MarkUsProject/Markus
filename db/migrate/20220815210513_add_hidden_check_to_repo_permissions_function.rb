class AddHiddenCheckToRepoPermissionsFunction < ActiveRecord::Migration[7.0]
  def up
    execute %(
DROP FUNCTION IF EXISTS check_repo_permissions(varchar, varchar, varchar);
CREATE FUNCTION check_repo_permissions(user_name_ varchar, course_name varchar, repo_name_ varchar)
RETURNS boolean
LANGUAGE plpgsql
AS
$$
DECLARE
    role_type varchar;
    role_id_ integer;
BEGIN
    SELECT roles.id, roles.type
    INTO role_id_, role_type
    FROM users
        JOIN roles ON roles.user_id=users.id
        JOIN courses ON roles.course_id=courses.id
    WHERE courses.name=course_name AND users.user_name=user_name_ AND roles.hidden=false
        FETCH FIRST ROW ONLY;

    IF role_type IN ('Instructor', 'AdminRole') THEN
        RETURN true;
    END IF;
    IF role_type = 'Ta' THEN
        RETURN EXISTS(
                SELECT 1
                FROM memberships
                    JOIN roles ON roles.id = memberships.role_id
                    JOIN groupings ON memberships.grouping_id = groupings.id
                    JOIN groups ON groupings.group_id = groups.id
                    JOIN assignment_properties ON assignment_properties.assessment_id = groupings.assessment_id
                WHERE memberships.type = 'TaMembership'
                  AND assignment_properties.anonymize_groups = false
                  AND roles.id = role_id_
                  AND groups.repo_name = repo_name_
            );
    END IF;
    IF role_type = 'Student' THEN
        RETURN EXISTS(
                SELECT roles.id
                FROM memberships
                    JOIN roles ON roles.id=memberships.role_id
                    JOIN groupings ON memberships.grouping_id=groupings.id
                    JOIN groups ON groupings.group_id=groups.id
                    JOIN assignment_properties ON assignment_properties.assessment_id=groupings.assessment_id
                    JOIN assessments ON groupings.assessment_id=assessments.id
                    JOIN courses ON assessments.course_id=courses.id
                    LEFT OUTER JOIN assessment_section_properties ON assessment_section_properties.assessment_id=assessments.id
                WHERE memberships.type='StudentMembership'
                  AND memberships.membership_status IN ('inviter','accepted')
                  AND assignment_properties.vcs_submit=true
                  AND roles.id=role_id_
                  AND courses.is_hidden=false
                  AND groups.repo_name=repo_name_
                  AND ((assessment_section_properties.is_hidden IS NULL AND assessments.is_hidden=false)
                           OR assessment_section_properties.is_hidden=false)
                  AND (assignment_properties.is_timed=false
                           OR groupings.start_time IS NOT NULL
                           OR (groupings.start_time IS NULL AND assessments.due_date<NOW()))
            );
    END IF;
    RETURN false;
END
$$;
)
  end

  def down
    execute %(
DROP FUNCTION IF EXISTS check_repo_permissions(varchar, varchar, varchar);
CREATE FUNCTION check_repo_permissions(user_name_ varchar, course_name varchar, repo_name_ varchar)
RETURNS boolean
LANGUAGE plpgsql
AS
$$
DECLARE
    role_type varchar;
    role_id_ integer;
BEGIN
    SELECT roles.id, roles.type
    INTO role_id_, role_type
    FROM users
        JOIN roles ON roles.user_id=users.id
        JOIN courses ON roles.course_id=courses.id
    WHERE courses.name=course_name AND users.user_name=user_name_
        FETCH FIRST ROW ONLY;

    IF role_type IN ('Instructor', 'AdminRole') THEN
        RETURN true;
    END IF;
    IF role_type = 'Ta' THEN
        RETURN EXISTS(
                SELECT 1
                FROM memberships
                    JOIN roles ON roles.id = memberships.role_id
                    JOIN groupings ON memberships.grouping_id = groupings.id
                    JOIN groups ON groupings.group_id = groups.id
                    JOIN assignment_properties ON assignment_properties.assessment_id = groupings.assessment_id
                WHERE memberships.type = 'TaMembership'
                  AND assignment_properties.anonymize_groups = false
                  AND roles.id = role_id_
                  AND groups.repo_name = repo_name_
            );
    END IF;
    IF role_type = 'Student' THEN
        RETURN EXISTS(
                SELECT roles.id
                FROM memberships
                    JOIN roles ON roles.id=memberships.role_id
                    JOIN groupings ON memberships.grouping_id=groupings.id
                    JOIN groups ON groupings.group_id=groups.id
                    JOIN assignment_properties ON assignment_properties.assessment_id=groupings.assessment_id
                    JOIN assessments ON groupings.assessment_id=assessments.id
                    LEFT OUTER JOIN assessment_section_properties ON assessment_section_properties.assessment_id=assessments.id
                WHERE memberships.type='StudentMembership'
                  AND memberships.membership_status IN ('inviter','accepted')
                  AND assignment_properties.vcs_submit=true
                  AND roles.id=role_id_
                  AND groups.repo_name=repo_name_
                  AND ((assessment_section_properties.is_hidden IS NULL AND assessments.is_hidden=false)
                           OR assessment_section_properties.is_hidden=false)
                  AND (assignment_properties.is_timed=false
                           OR groupings.start_time IS NOT NULL
                           OR (groupings.start_time IS NULL AND assessments.due_date<NOW()))
            );
    END IF;
    RETURN false;
END
$$;
)
  end
end
