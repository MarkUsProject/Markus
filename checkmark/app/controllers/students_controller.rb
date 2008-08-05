require 'csv'

# Manages actions relating to editing and modifying 
# students and the classlist.
class StudentsController < ApplicationController
  
  before_filter      :authorize
  
  # Publicly accessible actions ---------------------------------------
  
  def edit
    @student = User.find_by_id(params[:id])
    update_student if request.post?
  end
  
  # Creates a new student; handles both page display 
  # of creating a student and processing the form
  def create
    return unless request.post?
    attr = params[:student].merge(User.get_default_student_attrs)
    @student = User.new(attr)
    return unless @student.save
    redirect_to :controller => 'checkmark', :action => 'students'
  end
  
  # Renders XML format of the student claslist that is OLM-compatible
  def classlist
    request.headers["Content-Type"] = "application/xml" # declare link as xml
    @students = User.find_all_by_role(User::STUDENT)
    render :layout => false
  end
  
  
  # Form accessible actions --------------------------------------------
  # Post actions that we expect only forms to access them
  
  # TODO Attributes should be dynamically transformed to symbols
  # check db/schema.rb first to get current fields
  FIELDS = [:user_name, :user_number, :last_name, :first_name]
  
  # Updates the classlist
  def update_classlist
    if request.post? && !params[:classlist].blank?
     
      num_update = 0
      flash[:invalid_lines] = []  # store lines that were not processed
      # read each line of the file and update classlist
      CSV::Reader.parse(params[:classlist]) do |row|
        # don't know how to fetch line so we concat given array
        next if CSV.generate_line(row).strip.empty?
        if add_student(row) == nil
          flash[:invalid_lines] << row.join(",")
        else
          num_update += 1
        end
      end
      
      flash[:upload_notice] = "#{num_update} student(s) added/updated."
    end
    
    # display 'Manage Students' page
    redirect_to :controller => 'checkmark', :action => 'students'
  end
  
  protected
  
  # Update information for an individual student 
  def update_student
    redirect_to :controller => 'checkmark', :action => 'students' unless request.post?
    
    @student = User.find_by_id(params[:student][:id])
    attrs = params[:student].merge(User.get_default_student_attrs)
    return unless @student.update_attributes(attrs)
    
    flash[:edit_notice] = @student.user_name + " has been updated."
    redirect_to :controller => 'checkmark', :action => 'students'
  end
  
  # Helper methods ----------------------------------------------------
  
  # Creates or updates a student given the values hashed with FIELDS in 
  # the same specific order.  Returns nil if user has not been created or 
  # updated
  def add_student(values)
    # convert each line to a hash with FIELDS as corresponding keys 
    # and create or update a user with the hash values
    return nil if values.length < FIELDS.length
    
    attr = User.get_default_student_attrs
    FIELDS.zip(values) do |key, val|
      attr[key] = val unless val.blank?
    end
    
    User.update_on_duplicate(attr)
  end
  
end
