class AssignmentsController < ApplicationController
  
  before_filter      :authorize
  
  # Publicly accessible actions ---------------------------------------
  
  # Displays "Manage Assignments" page for creating and editing 
  # assignment information
  def index
    #TODO:  Shouldn't we just be pulling Assignments that this Professor created?
    @assignments = Assignment.all(:order => :id)
  end
  
  def edit
    @assignment = Assignment.find_by_id(params[:id])
    # TODO Code below is only temporary for migration
    # delete when all assignments have submission rules
    unless @assignment.submission_rule
      @assignment.submission_rule = SubmissionRule.new
      @assignment.student_form_groups = true  # default value
      @assignment.save
    end
  end
  
  def new
    @assignment = Assignment.new
    @assignment.assignment_files.build  # create at least one file
    @assignment.student_form_groups = true  # default value
    
    @assignment.submission_rule = SubmissionRule.new
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
    params[:files].each_value do |file|
      @assignment.assignment_files.build(file) unless file['filename'].blank?
    end if params[:files]
    
    # create and save new submission rule
    rule = SubmissionRule.new(params[:submission_rule])
    @assignment.submission_rule = rule if rule.valid?
    
    # Go back to "Create assignment" page if unable to save
    action = @assignment.save ? 'index' : 'new'
    redirect_to :action => action
  end
  
  # Called when form for updating existing assignment is submitted
  def update
    return unless request.post?
    
    @assignment = Assignment.find_by_id(params[:id])
    @assignment.attributes = params[:assignment]
    
    rules = @assignment.submission_rule
    # must be explicitly assigned, due to method conflict for "type"
    rules[:type] = params[:submission_rule][:type]
    rules.attributes = params[:submission_rule]
    
    # split text fields that exists in db and those that don't
    existing_files = {} # hash the id to the attribute values
    new_files = []
    params[:files].each_value do |f|
      id = f.delete("id")
      id.blank? ? new_files << f : existing_files[id.to_s] = f
    end if params[:files]
    
    # Update first existing files to see if filename 
    # has changed or has been deleted.
    @assignment.assignment_files.each do |file|
      attr = existing_files[file.id.to_s]
      attr ? file.attributes = attr : file.destroy # destroy if removed
    end
    
    # update the rest of the added text fields;
    # needs to be done after existing files are updated
    new_files.each do |file| 
      @assignment.assignment_files.build(file) unless file['filename'].blank?
    end
    
    # Go back to "Edit assignment" page if unable to save
    if (@assignment.save && @assignment.assignment_files.each(&:save) && rules.save)
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
    
  end

end
