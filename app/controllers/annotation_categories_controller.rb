require 'iconv'
require 'fastercsv'

class AnnotationCategoriesController < ApplicationController
  include AnnotationCategoriesHelper

  before_filter      :authorize_only_for_admin

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_categories = @assignment.annotation_categories
  end

  def get_annotations
    @annotation_category = AnnotationCategory.find(params[:id])
    @annotation_texts = @annotation_category.annotation_texts
  end

  def add_annotation_category
    @assignment = Assignment.find(params[:assignment_id])
    if request.post?
      # Attempt to add Annotation Category
      @annotation_category = AnnotationCategory.new
      @annotation_category.update_attributes(params[:annotation_category])
      @annotation_category.assignment = @assignment
      if !@annotation_category.save
        render :new_annotation_category_error
        return
      end
      render :insert_new_annotation_category
      return
    end
  end

  def update_annotation_category
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_category = AnnotationCategory.find(params[:id])

    @annotation_category.update_attributes(params[:annotation_category])
    if !@annotation_category.save
      flash.now[:error] = @annotation_category.errors
    else
      flash.now[:success] = I18n.t('annotations.update.annotation_category_success')
    end
  end

  def update_annotation
    @annotation_text = AnnotationText.find(params[:id])
    @annotation_text.update_attributes(params[:annotation_text])
    @annotation_text.save
  end

  def add_annotation_text
    @annotation_category = AnnotationCategory.find(params[:id])
    if request.post?
      # Attempt to add Annotation Text
      @annotation_text = AnnotationText.new
      @annotation_text.update_attributes(params[:annotation_text])
      @annotation_text.annotation_category = @annotation_category
      if !@annotation_text.save
        render :new_annotation_text_error
        return
      end
      @assignment = Assignment.find(params[:assignment_id])
      render :insert_new_annotation_text
      return
    end
  end

  def delete_annotation_text
    @annotation_text = AnnotationText.find(params[:id])
    @annotation_text.destroy
  end

  def delete_annotation_category
    @annotation_category = AnnotationCategory.find(params[:id])
    @annotation_category.destroy
  end

  def download
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_categories = @assignment.annotation_categories
    case params[:format]
    when 'csv'
      send_data convert_to_csv(@annotation_categories),
                :filename => "#{@assignment.short_identifier}_annotations.csv",
                :disposition => 'attachment'
    when 'yml'
      send_data convert_to_yml(@annotation_categories),
                :filename => "#{@assignment.short_identifier}_annotations.yml",
                :disposition => 'attachment'
    else
      flash[:error] = I18n.t("annotations.upload.flash_error",
                             :format => params[:format])
      redirect_to :action => 'index',
                  :id => params[:id]
    end
  end

  def csv_upload
    @assignment = Assignment.find(params[:assignment_id])
    encoding = params[:encoding]
    if !request.post?
      redirect_to :action => 'index', :id => @assignment.id
      return
    end
    annotation_category_list = params[:annotation_category_list_csv]
    annotation_category_number = 0
    annotation_line = 0
    if !annotation_category_list.nil?
      if encoding != nil
        annotation_category_list = StringIO.new(Iconv.iconv('UTF-8', encoding, annotation_category_list.read).join)
      end
      FasterCSV.parse(annotation_category_list.read) do |row|
        next if FasterCSV.generate_line(row).strip.empty?
        annotation_line += 1
        result = AnnotationCategory.add_by_row(row, @assignment)
        if result[:annotation_upload_invalid_lines].size > 0
           flash[:annotation_upload_invalid_lines] =
             I18n.t('annotations.upload.error',
                     :annotation_category => row,
                     :annotation_line => annotation_line)
          break
        else
          annotation_category_number += 1
        end
      end
      flash[:annotation_upload_success] = annotation_category_number > 0 ?
            I18n.t('annotations.upload.success',
                    :annotation_category_number => annotation_category_number) :
                    nil
    end
    redirect_to :action => 'index', :id => @assignment.id
  end

  def yml_upload
    @assignment = Assignment.find(params[:assignment_id])
    encoding = params[:encoding]
    if !request.post?
      redirect_to :action => 'index', :assignment_id => @assignment.id
      return
    end
    file = params[:annotation_category_list_yml]
    annotation_category_number = 0
    annotation_line = 0
    if !file.nil? && !file.blank?
      begin
        if encoding != nil
          file = StringIO.new(Iconv.iconv('UTF-8', encoding, file.read).join)
        end
        annotations = YAML::load(file)
      rescue ArgumentError => e
        flash[:annotation_upload_invalid_lines] =
             I18n.t('annotations.upload.syntax_error', :error => "#{e}")
         redirect_to :action => 'index', :assignment_id => @assignment.id
         return
      end
      annotations.each_key do |key|
      result = AnnotationCategory.add_by_array(key, annotations.values_at(key), @assignment)
      annotation_line += 1
      if result[:annotation_upload_invalid_lines].size > 0
           flash[:annotation_upload_invalid_lines] =
             I18n.t('annotations.upload.error',
                     :annotation_category => key,
                     :annotation_line => annotation_line)
          break
        else
          annotation_category_number += 1
        end
     end
     flash[:annotation_upload_success] = annotation_category_number > 0 ?
            I18n.t('annotations.upload.success',
                    :annotation_category_number => annotation_category_number) :
                    nil
    end
    redirect_to :action => 'index', :assignment_id => @assignment.id
  end
end
