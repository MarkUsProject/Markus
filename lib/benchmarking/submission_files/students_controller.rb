class StudentsController < ApplicationController
  include UsersHelper
  before_filter    :authorize_only_for_admin
  
  def index
    @students = Student.all(:order => "user_name")
  end
  
  def populate
    @students_data = Student.all(:order => "user_name")
    # construct_table_rows defined in UsersHelper
    @students = construct_table_rows(@students_data)
  end

  def edit
    @user = Student.find_by_id(params[:id]) 
  end 

  def update
    return unless request.post?
    @user = Student.find_by_id(params[:user][:id])
    attrs = params[:user]
    # update_attributes supplied by ActiveRecords
    if @user.update_attributes(attrs)
      flash[:edit_notice] = @user.user_name + ' has been updated.'
      redirect_to :action => 'index'
    else
      render :edit
    end
  end
  
  def bulk_modify
    student_ids = params[:student_ids]
    begin
      if student_ids.nil? || student_ids.empty?
        raise 'No students were selected, so no changes were made.'
      end
      case params[:bulk_action]
        when 'hide'
          Student.hide_students(student_ids)
          @students = construct_table_rows(Student.find(student_ids))
          return
        when 'unhide'
          Student.unhide_students(student_ids)
          @students = construct_table_rows(Student.find(student_ids))
          return
        when 'give_grace_credits'
          Student.give_grace_credits(student_ids, params[:number_of_grace_credits])
          @students = construct_table_rows(Student.find(student_ids))
          return
      end
    rescue RuntimeError => e
      @error = e.message
      render :display_error
    end
  end

  def filter
  case params[:filter]
    when 'hidden'
       @students = Student.all(:conditions => {:hidden => true}, :order => :user_name)
    when 'visible'
       @students = Student.all(:conditions => {:hidden => false}, :order => :user_name)
    else
      @students = Student.all(:order => :user_name)
    end

  end

  def create
    return unless request.post?
    # Default attributes: role = TA or role = STUDENT
    # params[:user] is a hash of values passed to the controller 
    # by the HTML form with the help of ActiveView::Helper::
    @user = Student.new(params[:user])
    # Return unless the save is successful; save inherted from
    # active records--creates a new record if the model is new, otherwise
    # updates the existing record
    return unless @user.save
    redirect_to :action => 'index' # Redirect 
  end
  

  #downloads users with the given role as a csv list
  def download_student_list
    #find all the users
    students = Student.all(:order => "user_name")
    case params[:format]
    when 'csv'
      output = User.generate_csv_list(students)
      format = 'text/csv'
    when 'xml'
      output = students.to_xml
      format = 'text/xml'
    else
      # Raise exception?
      output = students.to_xml
      format = 'text/xml'
    end
    send_data(output, :type => format, :disposition => 'inline')
  end
  
  def upload_student_list  
    if request.post? && !params[:userlist].blank?
      begin
        result = User.upload_user_list(Student, params[:userlist])
        if result[:invalid_lines].size > 0
          flash[:invalid_lines] = result[:invalid_lines]        
        end
        flash[:success] = result[:upload_notice]
      rescue RuntimeError
        flash[:upload_notice] = I18n.t('csv_valid_format')
      end

    end
    redirect_to :action => 'index'
  end  
 
end
