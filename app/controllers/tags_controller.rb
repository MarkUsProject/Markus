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
      flash[:success] = I18n.t('tags.create.successful')
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

  ###  Upload/Download Methods  ###

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
    send_data(output,
              type: format,
              filename: "tag_list.#{params[:format]}",
              disposition: 'inline')
  end

  def csv_upload
    # Gets parameters for the upload
    file = params[:csv_tags]
    encoding = params[:encoding]

    if request.post? && !file.blank?
      begin
        Tag.transaction do
          invalid_lines = []
          nb_updates = Tag.parse_csv(file,
                                     @current_user,
                                     invalid_lines,
                                     encoding)
          unless invalid_lines.empty?
            flash[:error] = I18n.t('csv_invalid_lines') +
                            invalid_lines.join(', ')
          end
          if nb_updates > 0
            flash[:success] = I18n.t('tags.upload.upload_success',
                                     nb_updates: nb_updates)
          end
        end
      end
    end
    redirect_to :back
  end

  def yml_upload

  end
end
