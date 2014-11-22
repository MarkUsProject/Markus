module TagsHelper
  def get_tags_table_info
    tags = Tag.all(order: 'name')

    tags.map do |tag|
      t = tag.attributes
      t[:user_name] = User.find(tag.user).first_name +
                      ' ' + User.find(tag.user).last_name
      t[:use] = get_num_groupings_for_tag(tag.id)
      t[:edit_link] = view_context.link_to(
          'Edit',
          edit_tag_dialog_assignment_tag_path(@assignment, tag),
          remote: true)
      t[:delete_link] = view_context.link_to(
          'Delete',
          controller: 'tags',
          action: 'destroy',
          data: { confirm: 'Are you sure you want to delete this tag?' },
          id: tag.id)
      t
    end
  end
end
