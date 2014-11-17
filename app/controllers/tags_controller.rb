class TagsController < ApplicationController
  include TagsHelper

  before_filter :authorize_only_for_admin

  def index
    respond_to do |format|
      format.html do
        @assignment = Assignment.find(params[:assignment_id])
      end
      format.json do
        render json: get_tags_table_info
      end
    end
  end

  # Creates a new instance of the tag.
  def create
    new_tag = Tag.new(
      name: params[:create_new][:name],
      description: params[:create_new][:description]) #TODO
      #user: @current_user,)

    if new_tag.save
      flash[:success] = I18n.t('tag created successfully')
      redirect_to :back
    else
      flash[:error] = I18n.t('error creating tag')
      redirect_to :back
    end
  end

  def get_all_tags
    Tag.all
  end

  # Destroys a particular tag.
  def destroy
    @tag = Tag.find(params[:id])
    @tag.destroy
  end

  ###  Update methods  ###

  def update_name
    Tag.update(params[:id], name: params[:name])
  end

  def update_description
    Tag.update(params[:id], description: params[:description])
  end

  ###  Grouping Methods ###

  def create_grouping_tag_association_from_existing_tag
    tag = Tag.find(params[:tag_id])
    create_grouping_tag_association(params[:grouping_id], tag)
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

  def delete_grouping_tag_association(grouping_id, tag_id)
    tag = Tag.find(tag_id)
    tag.groupings.delete(grouping_id)
  end
end
