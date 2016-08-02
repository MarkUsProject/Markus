module GradersHelper
  def get_graders_table_info_no_criteria(assignment)
    graders = Ta.all
    graders.map do |grader|
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
      g[:section] = grouping.section || '-'
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
    graders = Ta.all.includes(:criterion_ta_associations)
    ta_counts = assignment.criterion_ta_associations.group(:ta_id).count

    graders.map do |grader|
      g = grader.attributes
      g[:full_name] = "#{grader.first_name} #{grader.last_name}"
      g[:groups] = grader.get_membership_count_by_assignment(assignment)
      g[:criteria] = ta_counts[grader.id].to_s
      g[:criteria] += view_context.link_to(
        view_context.image_tag(
          'icons/comment.png',
          alt: I18n.t('criteria.title'),
          title: I18n.t('criteria.title')),
        grader_criteria_dialog_assignment_graders_path(
          id: assignment.id,
          grader: grader.id),
        remote: true)
      g
    end
  end

  # TODO: Refactor this method (split it up)
  def get_groups_table_info_with_criteria(assignment)
    groupings = groupings_with_assoc(assignment)
    total_criteria_count = assignment.criteria_count

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
      g[:coverage] = "#{assigned_count} / #{total_criteria_count}"
      if assigned_count == total_criteria_count
        g[:coverage] += view_context.link_to(
          view_context.image_tag(
            'icons/tick.png',
            alt: I18n.t('graders.covered'),
            title: I18n.t('graders.covered')),
          groups_coverage_dialog_assignment_graders_path(
            id: assignment.id,
            grouping: grouping.id),
          remote: true)
      else
        g[:coverage] += view_context.link_to(
          view_context.image_tag(
            'icons/cross.png',
            alt: I18n.t('graders.not_covered'),
            title: I18n.t('graders.not_covered')),
          groups_coverage_dialog_assignment_graders_path(
            id: assignment.id,
            grouping: grouping.id),
          remote: true)
      end
      g
    end

    criteria = criteria_with_assoc(assignment)
    criteria_table_info = criteria.map do |criterion|
      c = criterion.attributes
      c[:name] = criterion.name
      c[:class] = criterion.class.to_s
      c[:graders] = criterion.criterion_ta_associations.map do |association|
        m = association.attributes
        m[:user_name] = association.ta.user_name
        m[:criterion_association] = association.id
        m
      end

      assigned_length = criterion.assigned_groups_count
      c[:coverage] = "#{assigned_length} / #{assignment.groupings.size}"
      if assigned_length == assignment.groupings.size
        c[:coverage] += view_context.image_tag(
          'icons/tick.png',
          alt: I18n.t('graders.covered'),
          title: I18n.t('graders.covered'))
      else
        c[:coverage] += view_context.image_tag(
          'icons/cross.png',
          alt: I18n.t('graders.not_covered'),
          title: I18n.t('graders.not_covered'))
      end
      c
    end
    return {groups: groups_table_info, criteria: criteria_table_info}
  end
end
