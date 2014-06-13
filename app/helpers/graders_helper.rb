module GradersHelper

  # Given a list of criteria and an assignment, constructs an array of
  # table rows to be insterted into the criteria FilterTable in the graders view.
  # Called whenever it is necessary to update the criteria table with multiple
  # changes.
  def construct_criterion_table_rows(criteria, assignment)
    result = {}
    criteria.each do |criterion|
      result[criterion.id] = construct_criterion_table_row(criterion, assignment)
    end
    result
  end

  # Given a list of graders and an assignment, constructs an array of
  # table rows to be insterted into the graders FilterTable in the graders view.
  # Called whenever it is necessary to update the graders table with multiple
  # changes.
  def construct_grader_table_rows(graders, assignment)
    result = {}
    graders.each do |grader|
      result[grader.id] = construct_grader_table_row(grader, assignment)
    end
    result
  end

  # Given a list of groupings and an assignment, constructs an array of
  # table rows to be insterted into the groupings FilterTable in the graders view.
  # Called whenever it is necessary to update the groupings table with multiple
  # changes.
  def construct_table_rows(groupings, assignment)
    result = {}
    total_criteria_count = assignment.criteria_count
    groupings.each do |grouping|
      result[grouping.id] = construct_table_row(grouping, assignment, total_criteria_count)
    end
    result
  end

  def construct_table_row(grouping, assignment, total_criteria_count)
      table_row = {}

      table_row[:id] = grouping.id
      table_row[:filter_table_row_contents] =
        render_to_string partial: 'graders/table_row/filter_table_row',
        formats: [:html], handlers: [:erb],
        locals: { grouping: grouping,
                     assignment: assignment,
                     total_criteria_count: total_criteria_count }

      #These are used for sorting
      table_row[:name] = grouping.group.group_name
      # ta_memberships and their users are eagerly loaded and can be reused.
      table_row[:members] = grouping.ta_memberships
        .map { |ta_membership| ta_membership.user.user_name }
        .join(',')
      table_row[:coverage] = grouping.criteria_coverage_count

      #These 2 are used for searching
      table_row[:graders] = table_row[:members]
      table_row[:grader_names] = grouping.get_ta_names.join(',')

      #This one is used for selection
      table_row[:section] = grouping.section

      table_row
  end

  # Given a grader and an assignment, constructs a table row to be insterted
  # into the grader FilterTable in the graders view.  Called whenever it
  # is necessary to update the graders table.
  def construct_grader_table_row(grader, assignment)
    table_row = {}

    table_row[:id] = grader.id
    table_row[:filter_table_row_contents] =
      render_to_string partial: 'graders/table_row/filter_table_grader_row',
      locals: {grader: grader}

    #These used only for searching
    table_row[:first_name] = grader.first_name
    table_row[:last_name] = grader.last_name

    #These needed for sorting
    table_row[:user_name] = grader.user_name
    table_row[:full_name] = "#{grader.first_name} #{grader.last_name}"
    table_row[:num_groups] = grader.get_membership_count_by_assignment(assignment)
    table_row[:num_criteria] = grader.get_criterion_associations_count_by_assignment(assignment)

    table_row
  end

  # Given a criterion and an assignment, constructs a table row to be insterted
  # into the criteria FilterTable in the graders view.  Called whenever it
  # is necessary to update the criteria table.
  def construct_criterion_table_row(criterion, assignment)
    table_row = {}

    table_row[:id] = criterion.id
    table_row[:filter_table_row_contents] =
      render_to_string partial: 'graders/table_row/filter_table_criterion_row',
      formats: [:html], handlers: [:erb],
      locals: {criterion: criterion, assignment: assignment}

    table_row[:criterion_name] = criterion.get_name
    table_row[:members] = criterion.get_ta_names.to_s
    table_row[:coverage] = criterion.assigned_groups_count

    table_row
  end
end
