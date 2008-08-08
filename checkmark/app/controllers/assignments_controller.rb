class AssignmentsController < ApplicationController
  
  # Publicly accessible actions ---------------------------------------
  
  def edit
    @assignment = Assignment.find_by_id(params[:id])
    # assignment_file fetching will be done on the template
  end
  
  def new
    @assignment = Assignment.new
    @assignment.assignment_files.build  # create at least one file
  end
  
  # Ajax support for adding another file text field for this assignment
  def add_file
    @file = AssignmentFile.new
  end
  
  def remove_file
    if request.post? && params.has_key?('filename')
      
    end
  end
  

  # Form accessible actions --------------------------------------------
  # Post actions that we expect only forms to access them
  
  # Called when form for creating a new assignment is submitted
  def create
    return unless request.post?
    
    @assignment = Assignment.new(params[:assignment])
    build_files
    
    # Go back to "Create assignment" page if unable to save
    if @assignment.save
      redirect_to :controller => 'checkmark', :action => 'assignments'
    else
      render :action => 'new'
    end
  end
  
  # Called when form for updating existing assignment is submitted
  def update
    return unless request.post?
    
    @assignment = Assignment.find_by_id(params[:id])
    @assignment.attributes = params[:assignment]
    
    # delete all then recreate, more optimal and straightforward
    @assignment.assignment_files.destroy_all
    build_files
    
    # Go back to "Edit assignment" page if unable to save
    if @assignment.save
      redirect_to :controller => 'checkmark', :action => 'assignments'
    else
      render :action => 'edit'
    end
    
  end
  
  protected

  # helper method to create files for each of the file fields submitted
  def build_files
    return unless (params[:files] && @assignment)
    params[:files].each_value do |file|
      @assignment.assignment_files.build(file) unless file['filename'].blank?
    end
  end

  end
