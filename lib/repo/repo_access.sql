SELECT groups.repo_name, string_agg(users.user_name, ',') FROM assignment_properties
    JOIN groupings ON groupings.assessment_id=assignment_properties.assessment_id
    JOIN assessments ON assessments.id=assignment_properties.assessment_id
    JOIN memberships ON groupings.id = memberships.grouping_id
    JOIN users ON memberships.user_id = users.id
    JOIN groups ON groupings.group_id = groups.id
WHERE (assignment_properties.vcs_submit=true AND
      (assignment_properties.is_timed=false OR
       groupings.start_time IS NOT NULL OR
       (groupings.start_time IS NULL AND
        assessments.due_date < current_date))) OR
      users.type='Ta'
GROUP BY repo_name
UNION
SELECT '*' AS star, string_agg(users.user_name, ',') FROM users WHERE users.type='Admin' GROUP BY star;
