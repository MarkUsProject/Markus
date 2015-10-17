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
    else
      flash[:error] = I18n.t('tags.create.error')
    end

    redirect_to :back
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
    tags = Tag.all.order(:name)

    # Gets what type of format.
    case params[:format]
    when 'csv'
      output = Tag.generate_csv_list(tags)
      format = 'text/csv'
    when 'yaml'
      output = export_tags_yaml
      format = 'text/plain'
    else
      # If there is no 'recognized' format,
      # print to yaml.
      output = export_tags_yaml
      format = 'text/plain'
    end

    # Now we download the data.
    send_data(output,
              type: format,
              filename: "tag_list.#{params[:format]}",
              disposition: 'inline')
  end

  # Export a YAML formatted string.
  def export_tags_yaml
    tags = Tag.all(order: 'name')

    # The final list of all tags.
    final = ActiveSupport::OrderedHash.new

    # Go through and get each of the tags.
    tags.each do |tag|
      current = ActiveSupport::OrderedHash.new
      current['name'] =  tag['name']
      current['description'] = tag['description']

      # Gets user info.
      current_user = User.find(tag['user'])
      current['user'] = {
        'id' => tag['user'],
        'name' => "#{current_user['first_name']} #{current_user['last_name']}"
      }

      tag_yml = { "tag_#{tag['id']}" => current }
      final = final.merge(tag_yml)
    end

    # Outputs it to YAML.
    final.to_yaml
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
      rescue CSV::MalformedCSVError
        flash[:error] = t('csv.upload.malformed_csv')
      rescue ArgumentError
        flash[:error] = I18n.t('csv.upload.non_text_file_with_csv_extension')
      end
    end
    redirect_to :back
  end

  def yml_upload
    # Gets the parameters and encoding.
    errors = ActiveSupport::OrderedHash.new
    file = params[:yml_tags]
    encoding = params[:encoding]

    # Now carries out the parsing.
    if request.post? && !file.blank?
      begin
        tags = YAML::load(file.utf8_encode(encoding))

      # Handles errors associated with loads.
      rescue Psych::SyntaxError => e
        flash[:error] = I18n.t('tags.upload.error') + '  ' +
            I18n.t('tags.upload.syntax_error', error: "#{e}")
        redirect_to :back
        return
      end

      unless tags
        flash[:error] = I18n.t('tags.upload.error') +
            '  ' + I18n.t('tags.upload.empty_error')
        redirect_to :back
        return
      end

      # We now parse the file.
      successes = 0
      i = 1
      tags.each do |key|
        begin
          Tag.create_or_update_from_yml_key(key)
          successes += 1
        rescue RuntimeError => e
          # Collect the names of the criterion that contains an error in it.
          errors[i] = key.at(0)
          i = i + 1
        end
      end

      # Handles any errors.
      bad_names = ''
      i = 0
      # Create a String from the OrderedHash of bad criteria separated by commas.
      errors.each_value do |keys|
        if i == 0
          bad_names = keys
          i = i + 1
        else
          bad_names = bad_names + ', ' + keys
        end
      end

      if successes < tags.length
        flash[:error] = I18n.t('tags.upload.error') + bad_names
      end

      # Displays the tags that are successful.
      if successes > 0
        flash[:success] = I18n.t('tags.upload.upload_success', nb_updates: successes)
      end
    end

    # Redirects backwards.
    redirect_to :back
  end
end
