class StudentsController < ApplicationController
  before_filter    :authorize_only_for_admin
  
  def index
    @students = Student.find(:all, :order => "user_name")
    @hidden_students_number = Student.all(:conditions => {:hidden => true}).length
  end

  def edit
    @user = Student.find_by_id(params[:id]) 
  end 

  def update
    return unless request.post?
    @user = Student.find_by_id(params[:user][:id])
    attrs = params[:user]
    # update_attributes supplied by ActiveRecords
    if !@user.update_attributes(attrs)
      render :action => :edit
    else
      flash[:edit_notice] = @user.user_name + " has been updated."
      redirect_to :action => 'index'
    end
  end
  
  def bulk_modify
    @student_ids = params[:student_ids]
    @show_hidden_students = params[:show_hidden_students]
    case params[:bulk_action]
      when "hide"
        Student.hide_students(@student_ids)
        @hidden_students_number = Student.all(:conditions => {:hidden => true}).count
        render :action => "hide_students"
        return
      when "unhide"
        Student.unhide_students(@student_ids)
        @hidden_students_number = Student.all(:conditions => {:hidden => true}).count
        render :action => "unhide_students"
        return
    end
    # Nothing was done
    render :nothing => true
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
    students = Student.find(:all, :order => "user_name")
    case params[:format]
    when "csv"
      output = User.generate_csv_list(students)
      format = "text/csv"
    when "xml"
      output = students.to_xml
      format = "text/xml"
    else
      # Raise exception?
      output = students.to_xml
      format = "text/xml"
    end
    send_data(output, :type => format, :disposition => "inline")
  end
  
  def upload_student_list  
    if request.post? && !params[:userlist].blank?
      result = User.upload_user_list(Student, params[:userlist])
      if result[:invalid_lines].size > 0
        flash[:invalid_lines] = result[:invalid_lines]
      end
      flash[:upload_notice] = result[:upload_notice]
    end
    redirect_to :action => 'index'
  end  
 
end
