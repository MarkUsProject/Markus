# The actions necessary for managing grade entry forms.

class GradeEntryFormsController < ApplicationController
  include PaginationHelper
  
  before_filter      :authorize_only_for_admin

  # Filters will be added as the student UI is implemented (eg. Show Released, Show All,...)    
  G_TABLE_PARAMS = { :model => GradeEntryStudent, 
                     :per_pages => [15, 30, 50, 100, 150],
                     :filters => { 'none' => { :display => 'Show All', 
                                               :proc => lambda { Student.all(:conditions => {:hidden => false}, 
                                                                                             :order => "user_name")} }
                                 },
                     :sorts => { 'last_name' => lambda { |a,b| a.last_name.downcase <=> b.last_name.downcase} }                      
                   }
          
  # Create a new grade entry form
  def new
    @grade_entry_form = GradeEntryForm.new
    return unless request.post?
    
    # Process input properties
    @grade_entry_form.transaction do
      if @grade_entry_form.update_attributes(params[:grade_entry_form])
        # Success message
        flash[:success] = I18n.t('grade_entry_forms.create.success')
        redirect_to :action => "edit", :id => @grade_entry_form.id
      end
    end
  end 
  
  # Edit the properties of a grade entry form
  def edit
    @grade_entry_form = GradeEntryForm.find_by_id(params[:id])
    return unless request.post?
  
    # Process changes to input properties  
    @grade_entry_form.transaction do
      if @grade_entry_form.update_attributes(params[:grade_entry_form])
        # Success message
        flash[:success] = I18n.t('grade_entry_forms.edit.success')
        redirect_to :action => "edit", :id => @grade_entry_form.id
      end
    end
  end
  
  # View/modify the grades for this grade entry form
  def grades
    @grade_entry_form = GradeEntryForm.find_by_id(params[:id])
    @filter = 'none'
    
    # Pagination options
    @per_page = 15
    @current_page = 1
    @sort_by = 'last_name'
    @desc = false
    @filters = get_filters(G_TABLE_PARAMS)
    @per_pages = G_TABLE_PARAMS[:per_pages]
    
    all_students = get_filtered_items(G_TABLE_PARAMS, @filter, @sort_by, 
                                      {:grade_entry_form => @grade_entry_form})
    @students = all_students.paginate(:per_page => @per_page, :page => @current_page)
    @students_total = all_students.size
    @alpha_pagination_options = @grade_entry_form.alpha_paginate(all_students, @per_page, 
                                                                 @students.total_pages)
    session[:alpha_pagination_options] = @alpha_pagination_options
    @alpha_category = @alpha_pagination_options.first   
  end
  
  # Handle pagination for grades table
  # (The algorithm used to compute the alphabetical categories (alpha_paginate()) is
  # found in grade_entry_form.rb.)
  def g_table_paginate
    @grade_entry_form = GradeEntryForm.find(params[:id])
    @students, @students_total = handle_paginate_event(G_TABLE_PARAMS, 
                                                 {:grade_entry_form => @grade_entry_form}, 
                                                 params)

    @current_page = params[:page]
    @per_page = params[:per_page]
    @filters = get_filters(G_TABLE_PARAMS)
    @per_pages = G_TABLE_PARAMS[:per_pages]
    @desc = params[:desc]
    @filter = params[:filter]
    if !params[:sort_by].blank?  
      @sort_by = params[:sort_by]
    else  
      @sort_by = 'last_name'
    end
    
    # Only re-compute the alpha_pagination_options for the drop-down menu
    # if the number of items per page has changed
    if params[:update_alpha_pagination_options] == "true"
      all_students = get_filtered_items(G_TABLE_PARAMS, @filter, @sort_by, 
                                        {:grade_entry_form => @grade_entry_form})
      @alpha_pagination_options = @grade_entry_form.alpha_paginate(all_students, @per_page, 
                                                                   @students.total_pages)
      @alpha_category = @alpha_pagination_options.first
      session[:alpha_pagination_options] = @alpha_pagination_options
    else
      @alpha_pagination_options = session[:alpha_pagination_options]
      @alpha_category = params[:alpha_category]
    end
  end
  
  # Update a grade in the table
  def update_grade
    grade_entry_form = GradeEntryForm.find_by_id(params[:id])
    @student_id = params[:student_id]
    @grade_entry_item_id = params[:grade_entry_item_id]
    updated_grade = params[:updated_grade]
    grade_entry_student = grade_entry_form.grade_entry_students.find_or_create_by_user_id(@student_id)
    @grade = grade_entry_student.grades.find_or_create_by_grade_entry_item_id(@grade_entry_item_id)
    @grade.grade = updated_grade
    @grade_saved = @grade.save
    @updated_student_total = grade_entry_form.calculate_total_mark(@student_id)
  end
  
end
