module GroupsHelper
  # Gets information needed to display students
  # in the table on the front-end. Returns
  # an array of hashes.
  def get_students_table_info
    students = Student.all
    student_memberships = StudentMembership
                          .includes(:user)
                          .where(grouping_id: @assignment.groupings)

    students_in_assignment = student_memberships.map do |membership|
      membership.user
    end

    students.map do |student|
      s = student.attributes
      s['assigned'] = students_in_assignment.include?(student)
      s
    end
  end

  # Gets information needed to display group info
  # on the front-end. Attributes include URLs for actions
  # such as validation, renaming, showing notes, etc.
  def get_groupings_table_info(target_assignment=nil)
    if target_assignment.nil?
      target_assignment = @assignment
    end

    groupings = target_assignment.groupings
                           .includes(:group,
                                     :non_rejected_student_memberships,
                                     :students,
                                     :inviter)
    groupings.map do |grouping|
      g = grouping.attributes
      g[:name] = grouping.group.group_name
      g[:members] = grouping.students
      g[:section] = grouping.section
      g[:valid] = grouping.is_valid?
      g[:validate_link] = view_context.link_to(
        view_context.image_tag(
          'icons/cross.png',
          alt: I18n.t('groups.is_not_valid'),
          title: I18n.t('groups.is_not_valid')),
          valid_grouping_assignment_groups_path(
            grouping_id: grouping.id),
          confirm:  I18n.t('groups.validate_confirm'),
        remote: true)

      g[:invalidate_link] = view_context.link_to(
        view_context.image_tag(
          'icons/tick.png',
          alt: I18n.t('groups.is_valid'),
          title: I18n.t('groups.is_valid')),
        invalid_grouping_assignment_groups_path(
          grouping_id: grouping.id),
          confirm:  I18n.t('groups.invalidate_confirm'),
        remote: true)

      rename_link = rename_group_assignment_group_path(target_assignment, grouping)
      g[:rename_link] = view_context.link_to(
        view_context.image_tag(
          'icons/pencil.png',
          alt: I18n.t('groups.rename_group.link'),
          title: I18n.t('groups.rename_group.link')),
        'javascript:void(0);',
        onclick:"modal_rename.open();"\
                "jQuery('#rename_group_dialog form').attr('action', '#{rename_link}')")

      g[:note_link] = view_context.link_to(
        view_context.image_tag(
          'icons/note.png',
          alt: I18n.t('notes.title'),
          title: I18n.t('notes.title')),
        notes_dialog_note_path(
          id: target_assignment.id,
          noteable_id: grouping.id,
          noteable_type: 'Grouping',
          action_to: 'note_message',
          controller_to: 'groups'),
        remote: true)

      g[:delete_link] = view_context.link_to(
        view_context.image_tag(
          'icons/bin_closed.png',
          alt: I18n.t('groups.delete')),
        remove_group_assignment_groups_path(
          grouping_id:  grouping.id),
        method: 'delete',
        confirm:  I18n.t('groups.delete_confirm'),
        remote: true)
      g
    end
  end
end
