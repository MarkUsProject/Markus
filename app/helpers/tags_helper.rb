module TagsHelper
  ###  Global Tag Methods  ###

  def get_top_tags
    # Sorts all the tags by number of groupings.
    sorted_tag = Tag.all.sort_by do |tag|
      get_num_groupings_for_tag(tag)
    end

    # Loops until the top 5 tags are found
    i = sorted_tag.length - 1
    top ||= []
    while i >= sorted_tag.length - 5 && i >= 0
      top << sorted_tag.at(i)
      i -= 1
    end

    top
  end

  ###  Update methods  ###

  def update_name
    Tag.update(params[:id], name: params[:name])
  end

  def update_description
    Tag.update(params[:id], description: params[:description])
  end

  ###  Grouping Methods  ###

  def create_grouping_tag_association_from_existing_tag(grouping_id, tag_id)
    tag = Tag.find(tag_id)
    create_grouping_tag_association(grouping_id, tag)
  end

  def create_grouping_tag_association(grouping_id, tag)
    if !tag.groupings.exists?(grouping_id)
      grouping = Grouping.find(grouping_id)
      tag.groupings << (grouping)
    end
  end

  def get_tags_for_grouping(grouping_id)
    grouping = Grouping.find(grouping_id)
    grouping.tags
  end

  def get_num_groupings_for_tag(tag)
    tag.groupings.size
  end

  def get_tags_not_associated_with_grouping(g_id)
    grouping = Grouping.find(g_id)
    grouping_tags = grouping.tags

    all_tags = Tag.all.select do |t|
      !grouping_tags.include?(t)
    end

    all_tags
  end

  def delete_grouping_tag_association(tag_id, grouping_id)
    tag = Tag.find(tag_id)
    tag.groupings.delete(grouping_id)
  end
end
