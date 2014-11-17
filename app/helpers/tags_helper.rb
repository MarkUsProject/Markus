module TagsHelper
  def get_tags_table_info
    tags = Tag.all(order: 'name')

    tags.map do |tag|
      t = tag.attributes
      t[:edit_link] = url_for(
          controller: 'tags',
          action: 'edit',
          id: tag.id)
      t[:delete_link] = url_for(
          controller: 'tags',
          action: 'delete',
          id: tag.id)

      t
    end
  end
end
