class TagsController < ApplicationController
  include TagsHelper

  before_filter :authorize_only_for_admin

  def index
    @assignment = Assignment.find(params[:assignment_id])

    respond_to do |format|
      format.html
      format.json do
        @assignment = Assignment.find(params[:assignment_id])
        render json: get_tags_table_info
      end
    end
  end

  def edit
    @tag = Tag.find(params[:id])
    @assignment = Assignment.find(params[:assignment_id])
  end

  # Creates a new instance of the tag.
  def create
    new_tag = Tag.new(
      name: params[:create_new][:name],
      description: params[:create_new][:description],
      user: @current_user)

    if new_tag.save
      flash[:success] = I18n.t('tag created successfully')
      if params[:grouping_id]
        create_grouping_tag_association(params[:grouping_id], new_tag)
      end
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

    respond_to do |format|
      format.html do
        redirect_to :back
      end
    end
  end

  # Dialog to edit a tag.
  def edit_tag_dialog
    @assignment = Assignment.find(params[:assignment_id])
    @tag = Tag.find(params[:id])

    render partial: 'tags/edit_dialog', handlers: [:erb]
  end

  ###  Update methods  ###

  def update_tag
    # Updates both the name and ID.
    Tag.update(params[:id], name: params[:update_tag][:name])
    Tag.update(params[:id], description: params[:update_tag][:description])

    respond_to do |format|
      format.html do
        redirect_to :back
      end
    end
  end

  def update_name
    Tag.update(params[:id], name: params[:name])
  end

  def update_description
    Tag.update(params[:id], description: params[:description])
  end

  ###  Upload/Download Methods ###

  def download_tag_list
    # Gets all the tags
    tags = Tag.all(order: 'name')

    #Gets what type of format.
    case params[:format]
      when 'csv'
        output = Tag.generate_csv_list(tags)
        format = 'text/csv'
      when 'xml'
        output = tags.to_xml
        format = 'text/xml'
      else
        # If there is no 'recognized' format,
        # print to xml.
        output = tags.to_xml
        format = 'text/xml'
    end

    # Now we download the data.
    send_data(output, type: format, filename: "tag_list.#{params[:format]}", disposition: 'inline')
  end

  def csv_upload
    file = params[:csv_upload][:rubric]
    @assignment = Assignment.find(params[:assignment_id])
    encoding = params[:encoding]
    if request.post? && !file.blank?
      begin
        RubricCriterion.transaction do
          invalid_lines = []
          nb_updates = RubricCriterion.parse_csv(file, @assignment, invalid_lines, encoding)
          unless invalid_lines.empty?
            flash[:error] = I18n.t('csv_invalid_lines') + invalid_lines.join(', ')
          end
          if nb_updates > 0
            flash[:notice] = I18n.t('rubric_criteria.upload.success',
                                    nb_updates: nb_updates)
          end
        end
      end
    end
    redirect_to :back
  end

  def yml_upload

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

  def get_tags_for_grouping
    grouping = Grouping.find(params[:grouping_id])
    grouping.tags
  end

  def get_num_groupings_for_tag(tag_id)
    tag = Tag.find(tag_id)
    count = 0

    Grouping.all.each do |group|
      if tag.groupings.exists?(group.id)
        count += 1
      end
    end

    count
  end

  def get_tags_not_associated_with_grouping
    grouping = Grouping.find(:params[grouping_id])
    grouping_tags = grouping.tags

    all_tags = get_all_tags
    all_tags.delete_if do |t|
      grouping_tags.include?(t)
    end

    all_tags
  end

  def delete_grouping_tag_association
    tag = Tag.find(params[:tagging_id])
    tag.groupings.delete(params[:grouping_id])
  end
end
