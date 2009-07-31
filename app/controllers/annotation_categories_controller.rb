class AnnotationCategoriesController < ApplicationController

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
        render :action => 'new_annotation_category_error'
        return
      end
      render :action => 'insert_new_annotation_category'
      return
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
        render :action => 'new_annotation_text_error'
        return
      end
      render :action => 'insert_new_annotation_text'
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
end
