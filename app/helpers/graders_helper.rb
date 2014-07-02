module GradersHelper
  def get_graders_table_info_no_criteria(assignment)
    graders = Ta.all
    graders_table_info = graders.map do |grader|
      g = grader.attributes
      g[:full_name] = "#{grader.first_name} #{grader.last_name}"
      g[:groups] = grader.get_membership_count_by_assignment(assignment)
      g[:criteria] = I18n.t('all')
      g
    end
  end

  def get_groups_table_info_no_criteria(assignment)
    groupings = groupings_with_assoc(assignment)
    groups_table_info = groupings.map do |grouping|
      g = grouping.attributes
      g[:name] = grouping.group.group_name
      g[:students] = grouping.students
      g[:section] = grouping.section
      g[:graders] = grouping.ta_memberships.map do |membership|
        m = {}
        m[:user_name] = membership.user.user_name
        m[:membership_id] = membership.id
        m
      end
      g
    end
    return {groups: groups_table_info, criteria: []}
  end

  def get_graders_table_info_with_criteria(assignment)
    graders = Ta.all
    graders_table_info = graders.map do |grader|
      g = grader.attributes
      g[:full_name] = "#{grader.first_name} #{grader.last_name}"
      g[:groups] = grader.get_membership_count_by_assignment(assignment)
      g[:criteria] = grader.get_criterion_associations_count_by_assignment(@assignment).to_s
      g[:criteria] += ActionController::Base.helpers.link_to(
        ActionController::Base.helpers.image_tag('icons/comment.png',
                                                 alt: I18n.t('criteria'),
                                                 title: I18n.t('criteria')),
        grader_criteria_dialog_assignment_graders_path(
          id: @assignment.id, grader: grader.id),
        remote: true)
      g
    end
  end

  def get_groups_table_info_with_criteria(assignment)
    groupings = groupings_with_assoc(assignment)
    groups_table_info = groupings.map do |grouping|
      g = grouping.attributes
      g[:name] = grouping.group.group_name
      g[:students] = grouping.students
      g[:section] = grouping.section
      g[:graders] = grouping.ta_memberships.map do |membership|
        m = {}
        m[:user_name] = membership.user.user_name
        m[:membership_id] = membership.id
        m
      end

      assigned_count = grouping.criteria_coverage_count
      total_criteria_count = assignment.criteria_count
      g[:coverage] = "#{assigned_count} / #{total_criteria_count}"
      if assigned_count == total_criteria_count
        g[:coverage] += ActionController::Base.helpers.link_to(
        ActionController::Base.helpers.image_tag('icons/tick.png',
                                                 alt: I18n.t('graders.covered'),
                                                 title: I18n.t('graders.covered')),

        groups_coverage_dialog_assignment_graders_path(id: assignment.id, 
                                                       grouping: grouping.id),
        remote: true)
      else
        g[:coverage] += ActionController::Base.helpers.link_to(
        ActionController::Base.helpers.image_tag('icons/cross.png',
                                                 alt: I18n.t('graders.not_covered'),
                                                 title: I18n.t('graders.not_covered')),

        groups_coverage_dialog_assignment_graders_path(id: assignment.id, 
                                                       grouping: grouping.id),
        remote: true)
      end
      g
    end

    criteria = criteria_with_assoc(assignment)
    criteria_table_info = criteria.map do |criterion|
      c = criterion.attributes
      if assignment.marking_scheme_type == "rubric"
        c[:name] = criterion.rubric_criterion_name
      else
        c[:name] = criterion.flexible_criterion_name
      end
      c[:graders] = criterion.criterion_ta_associations.map do |association|
        m = association.attributes
        m[:user_name] = association.ta.user_name
        m[:criterion_association] = association.id
        m
      end

      assigned_length = criterion.assigned_groups_count
      c[:coverage] = "#{assigned_length} / #{assignment.groupings.size}"
      if assigned_length == assignment.groupings.size
        c[:coverage] += ActionController::Base.helpers.image_tag('icons/tick.png',
          alt: I18n.t('graders.covered'),
          title: I18n.t('graders.covered'))
      else
        c[:coverage] += ActionController::Base.helpers.image_tag('icons/cross.png',
          alt: I18n.t('graders.not_covered'),
          title: I18n.t('graders.not_covered'))
      end
      c
    end
    return {groups: groups_table_info, criteria: criteria_table_info}
  end

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
