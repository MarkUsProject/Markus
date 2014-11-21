module TagsHelper
  def get_tags_table_info
    tags = Tag.all(order: 'name')

    tags.map do |tag|
      t = tag.attributes
      t[:user_name] = User.find(tag.user).first_name +
                      ' ' + User.find(tag.user).last_name
      t[:use] = get_num_groupings_for_tag(tag.id)
      t[:edit_link] = url_for(
          controller: 'tags',
          action: 'edit',
          id: tag.id)
      t[:delete_link] = url_for(
          controller: 'tags',
          action: 'destroy',
          id: tag.id)
      t
    end
  end
end
