class StudentsController < ApplicationController
  include UsersHelper
  before_filter    :authorize_only_for_admin

  def note_message
    @student = Student.find(params[:id])
    if params[:success]
      flash[:success] = I18n.t('notes.create.success')
    else
      flash[:error] = I18n.t('notes.error')
    end
  end

  def index
    respond_to do |format|
      format.html do # Renders students/index.html.erb
        @columns = { 'user_name' => I18n.t('user.user_name'),
                     'last_name' => I18n.t('user.last_name'),
                     'first_name' => I18n.t('user.first_name'),
                     'section' => I18n.t('user.section'),
                     'grace_credits' => I18n.t('user.grace_credits'),
                     'notes' => I18n.t('user.notes_count'),
                     'edit' => I18n.t('edit') }
        @rows = { 'edit' => I18n.t('edit'),
                  'notes' => I18n.t('user.notes_count') }
        @search = I18n.t('students.search_students')
        @filters = { 'all' => I18n.t('all'),
                     'active' => I18n.t('active'),
                     'not_active' => I18n.t('not_active') }
        @actions = { 'give_grace_credits' => I18n.t('give_grace_credits'),
                     'add_section' => I18n.t('add_section'),
                     'no_sections' => I18n.t('section.no_sections'),
                     'hide_students' => I18n.t('hide_students'),
                     'unhide_students' => I18n.t('unhide_students') }
      end
      format.json do
        @sections = Section.all
        @students = Student.includes(:grace_period_deductions, :section)
                           .all(order: 'user_name')
        # Gets extra info needed to table, such as grace credits remaining,
        # links to edit, notes, etc.
        @students_table_info = @students.map do |student|
          s = student.attributes
          s['edit_link'] = url_for(controller: 'students',
                                   action: 'edit',
                                   id: student.id)
          s['grace_credits_remaining'] = student.remaining_grace_credits
          s['section_name'] = student.has_section? ? student.section.name : nil
          s['notes_link'] = url_for(controller: 'notes',
                                    action: 'notes_dialog',
                                    id: student.id,
                                    noteable_id: student.id,
                                    noteable_type: 'Student',
                                    action_to: 'note_message',
                                    controller_to: 'students',
                                    number_of_notes_field:
                                      "num_notes_#{student.id}",
                                    highlight_field:
                                      "notes_highlight_#{student.id}")
          s['num_notes'] = student.notes.size
          s
        end
        render json: [@students_table_info]
      end
    end
  end

  def edit
    @user = Student.find_by_id(params[:id])
    @sections = Section.all(:order => 'name')
  end

  def update
    @user = Student.find_by_id(params[:id])
    attrs = params[:user]
    # update_attributes supplied by ActiveRecords
    if @user.update_attributes(attrs)
      flash[:success] = I18n.t('students.update.success',
                               :user_name => @user.user_name)
      redirect_to :action => 'index'
    else
      flash[:error] = I18n.t('students.update.error')
      @sections = Section.all(:order => 'name')
      render :edit
    end
  end

  def bulk_modify
    student_ids = params[:student_ids]
    begin
      if student_ids.nil? || student_ids.empty?
        raise I18n.t('students.no_students_selected')
      end
      case params[:bulk_action]
      when 'hide'
        Student.hide_students(student_ids)
      when 'unhide'
        Student.unhide_students(student_ids)
      when 'give_grace_credits'
        Student.give_grace_credits(student_ids,
                                   params[:number_of_grace_credits])
      when 'update_section'
        Student.update_section(student_ids, params[:section])
      end
      head :ok
    rescue RuntimeError => e
      @error = e.message
      render :display_error
    end
  end

  def new
    @user = Student.new(params[:user])
    @sections = Section.all(:order => 'name')
  end

  def create
    # Default attributes: role = TA or role = STUDENT
    # params[:user] is a hash of values passed to the controller
    # by the HTML form with the help of ActiveView::Helper::
    @user = Student.new(params[:user])
    if @user.save
      flash[:success] = I18n.t('students.create.success',
                               :user_name => @user.user_name)
      redirect_to :action => 'index' # Redirect
    else
      @sections = Section.all(:order => 'name')
      flash[:error] = I18n.t('students.create.error')
      render :new
    end
  end

  # dummy action for remote rjs calls
  # triggered by clicking on the "add a new section" link in the new student page
  # please keep.
  def add_new_section
     @section = Section.new
  end

  #downloads users with the given role as a csv list
  def download_student_list
    #find all the users
    students = Student.all(:order => 'user_name')
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
        result = User.upload_user_list(Student, params[:userlist], params[:encoding])
        if result[:invalid_lines].size > 0
          flash[:error] = I18n.t('csv_invalid_lines') +
            result[:invalid_lines].join(', ')
        end
        flash[:success] = result[:upload_notice]
      rescue RuntimeError
        flash[:notice] = I18n.t('csv_valid_format')
      end

    end
    redirect_to :action => 'index'
  end

  def delete_grace_period_deduction
    grace_deduction = GracePeriodDeduction.find(params[:deduction_id])
    student_id = grace_deduction.membership.user.id
    grace_deduction.destroy
    student = Student.find(student_id)
    @grace_period_deductions = student.grace_period_deductions
  end

end
