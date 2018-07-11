class AnnotationCategoriesController < ApplicationController
  include AnnotationCategoriesHelper

  before_action      :authorize_only_for_admin, except: :index
  before_action      :authorize_for_ta_and_admin, only: :index

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_categories = @assignment.annotation_categories.order(:position).includes(:annotation_texts)

    respond_to do |format|
      format.html
      format.json {
        data = @annotation_categories.map do |cat|
          {
            id: cat.id,
            annotation_category_name: cat.annotation_category_name,
            texts: cat.annotation_texts.map do |text|
              {
                id: text.id,
                content: text.content
              }
            end
          }
        end
        render json: data
      }
    end
  end

  def new
    @assignment = Assignment.find(params[:assignment_id])
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_category = @assignment.annotation_categories
                                      .new(annotation_category_params)
    if @annotation_category.save
      flash_message(:success, t('.success'))
      render :insert_new_annotation_category
    else
      render :new_annotation_category_error
    end
  end

  def show
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_category = AnnotationCategory.find(params[:id])
  end

  def destroy
    @annotation_category = AnnotationCategory.find(params[:id])
    if @annotation_category.destroy
      flash_message(:success, t('.success'))
    end
  end

  def update
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_category = AnnotationCategory.find(params[:id])

    @annotation_category.update_attributes(annotation_category_params)
    if @annotation_category.save
      flash.now[:success] = t('.success')
    else
      flash.now[:error] = @annotation_category.errors.full_messages
    end
  end

  def update_annotation
    @annotation_text = AnnotationText.find(params[:id])
    @annotation_text.update_attributes(annotation_text_params)
    @annotation_text.last_editor_id = current_user.id
    if @annotation_text.save
      flash_now(:success, t('annotation_categories.update.success'))
    end
  end

  def add_annotation_text
    @annotation_category = AnnotationCategory.find(params[:id])
    if request.post?
      # Attempt to add Annotation Text
      @annotation_text = AnnotationText.new
      @annotation_text.update_attributes(annotation_text_params)
      @annotation_text.annotation_category = @annotation_category
      @annotation_text.creator_id = current_user.id
      @annotation_text.last_editor_id = current_user.id
      unless @annotation_text.save
        render :new_annotation_text_error
        return
      end
      flash_now(:success, t('annotation_categories.update.success'))
      @assignment = Assignment.find(params[:assignment_id])
      render :insert_new_annotation_text
    end
  end

  def delete_annotation_text
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_text = AnnotationText.find(params[:id])
    if @annotation_text.destroy
      flash_now(:success, t('.success'))
    end
  end

  def find_annotation_text
    @assignment = Assignment.find(params[:assignment_id])
    string = params[:string]
    texts_for_current_assignment = AnnotationText.joins(annotation_category: :assignment).
        where(assignments: {id: @assignment.id})
    annotation_texts = texts_for_current_assignment.where("content LIKE ?", "#{string}%")
    if annotation_texts.size == 1
      render json: "#{annotation_texts.first.content}".html_safe
    else
      render json: ''.html_safe
    end
  end

  # This method handles the drag/drop Annotations sorting
  def update_positions
    unless request.post?
      head :ok
      return
    end

    @assignment = Assignment.find(params[:assignment_id])
    @annotation_categories = @assignment.annotation_categories
    position = 0

    params[:annotation_category].each do |id|
      if id != ''
        position += 1
        AnnotationCategory.update(id, position: position)
      end
    end
  end

  def download
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_categories = @assignment.annotation_categories
    case params[:format]
      when 'csv'
        ac = prepare_for_conversion(@annotation_categories)
        file_out = MarkusCSV.generate(
          ac) do |annotation_category_name, annotation_texts|
          # csv format is annotation_category.name, annotation_text.content
          annotation_texts.unshift(annotation_category_name)
        end
        send_data file_out,
                  filename: "#{@assignment.short_identifier}_annotations.csv",
                  disposition: 'attachment'
      when 'yml'
        send_data convert_to_yml(@annotation_categories),
                  filename: "#{@assignment.short_identifier}_annotations.yml",
                  disposition: 'attachment'
      else
        flash[:error] = t('download_errors.unrecognized_format',
                          format: params[:format])
        redirect_to action: 'index',
                    id: params[:id]
    end
  end

  def csv_upload
    @assignment = Assignment.find(params[:assignment_id])
    encoding = params[:encoding]
    unless request.post?
      redirect_to action: 'index', id: @assignment.id
      return
    end
    annotation_category_list = params[:annotation_category_list_csv]
    if annotation_category_list
      result = MarkusCSV.parse(annotation_category_list.read, encoding: encoding) do |row|
        next if CSV.generate_line(row).strip.empty?
        AnnotationCategory.add_by_row(row, @assignment, current_user)
      end
      unless result[:invalid_lines].empty?
        flash_message(:error, result[:invalid_lines])
      end
      unless result[:valid_lines].empty?
        flash_message(:success, result[:valid_lines])
      end
    else
      flash_message(:error, I18n.t('csv.invalid_csv'))
    end
    redirect_to action: 'index', id: @assignment.id
  end

  def yml_upload
    @assignment = Assignment.find(params[:assignment_id])
    encoding = params[:encoding]
    unless request.post?
      redirect_to action: 'index', assignment_id: @assignment.id
      return
    end
    file = params[:annotation_category_list_yml]
    annotation_category_number = 0
    annotation_line = 0
    unless file.blank?
      begin
        annotations = YAML::load(file.utf8_encode(encoding))
      rescue Psych::SyntaxError => e
        flash_message(:error,
                      t('upload_errors.syntax_error', error: "#{e}"))
        redirect_to action: 'index', assignment_id: @assignment.id
        return
      end

      # YAML::load returns a hash if successful
      unless annotations.is_a? Hash
        flash_message(:error, I18n.t('upload_errors.unparseable_yml'))
        redirect_to action: 'index', assignment_id: @assignment.id
        return
      end

      annotations.each_key do |key|
      result = AnnotationCategory.add_by_array(key, annotations.values_at(key), @assignment, current_user)
      annotation_line += 1
      if result[:annotation_upload_invalid_lines].size > 0
        flash_message(:error, t('annotation_categories.upload.error',
                                annotation_category: key, annotation_line: annotation_line))
        break
      else
        annotation_category_number += 1
      end
     end
     if annotation_category_number > 0
       flash_message(:success, t('annotation_categories.upload.success',
                                 annotation_category_number: annotation_category_number))
     end
    end
    redirect_to action: 'index', assignment_id: @assignment.id
  end

  private

  def annotation_category_params
    # we do not want to allow :position to be given directly
    params.require(:annotation_category)
          .permit(:annotation_category_name, :assignment_id)
  end

  def annotation_text_params
    params.require(:annotation_text).permit(:content)
  end
end
