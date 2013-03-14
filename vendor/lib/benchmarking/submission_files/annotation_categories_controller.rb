require 'fastercsv'

class AnnotationCategoriesController < ApplicationController
  include AnnotationCategoriesHelper
  def index
    @assignment = Assignment.find(params[:id])
    @annotation_categories = @assignment.annotation_categories
  end
  
  def get_annotations
    @annotation_category = AnnotationCategory.find(params[:id])
    @annotation_texts = @annotation_category.annotation_texts
  end
  
  def add_annotation_category
    @assignment = Assignment.find(params[:id])
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
    @assignment = Assignment.find(params[:id])
    @annotation_categories = @assignment.annotation_categories
    case params[:format]
    when 'csv'
      send_data convert_to_csv(@annotation_categories), :type => 'csv', :disposition => 'attachment'
    when 'yml'
      send_data convert_to_yml(@annotation_categories), :type => 'yml', :disposition => 'attachment'
    else
      flash[:error] = "Could not recognize #{params[:format]} format to download with"
      redirect_to :action => 'index', :id => params[:id]
    end
  end
  
  def csv_upload
    @assignment = Assignment.find(params[:id])
    if !request.post? 
      redirect_to :action => 'index', :id => @assignment.id
    end
    annotation_category_list = params[:annotation_category_list]
    annotation_category_number = 0
    FasterCSV.parse(annotation_category_list) do |row|
      next if FasterCSV.generate_line(row).strip.empty?
      if !AnnotationCategory.add_by_row(row, @assignment)
        flash[:annotation_upload_invalid_lines] << row.join(",")
      else
        annotation_category_number += 1
      end
    end 
    flash[:annotation_upload_success] = I18n.t('annotations.upload.success', :annotation_category_number => annotation_category_number)
    redirect_to :action => 'index', :id => @assignment.id
  end
end
