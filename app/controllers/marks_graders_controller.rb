# Manages actions relating to assigning graders.
class MarksGradersController < ApplicationController
  before_action :authorize_only_for_admin

  layout 'assignment_content'

  def index
    respond_to do |format|
      format.html { @grade_entry_form = GradeEntryForm.find(params[:grade_entry_form_id]) }
      format.json do
        gef = GradeEntryForm.find(params[:grade_entry_form_id])

        # Grader information
        counts = Ta.joins(:grade_entry_students)
                   .where('grade_entry_students.grade_entry_form_id': gef.id)
                   .group('users.id')
                   .count

        graders = Ta.pluck(:id, :user_name, :first_name, :last_name).map do |ta_data|
          {
            _id: ta_data[0],
            user_name: ta_data[1],
            first_name: ta_data[2],
            last_name: ta_data[3],
            students: counts[ta_data[0]] || 0
          }
        end

        # Student information
        student_data = gef.grade_entry_students
                          .left_outer_joins(:user, :tas)
                          .pluck('users.id',
                                 'users.user_name',
                                 'users.first_name',
                                 'users.last_name',
                                 'tas_grade_entry_students.user_name')

        students = Hash.new { |h, k| h[k] = [] }
        student_data.each do |s0, s1, s2, s3, ta|
          students[[s0, s1, s2, s3]] # Touch to set default value
          unless ta.nil?
            students[[s0, s1, s2, s3]] << ta
          end
        end
        section_data = Student.joins(:section).pluck('users.id', 'sections.name').to_h
        students = students.map do |k, v|
          {
            _id: k[0],
            user_name: k[1],
            first_name: k[2],
            last_name: k[3],
            section: section_data[k[0]],
            graders: v
          }
        end

        render json: {
          graders: graders,
          students: students
        }
      end
    end
  end

  # Assign TAs to Students via a csv file
  def csv_upload_grader_groups_mapping
    if params[:grader_mapping].nil?
      flash_message(:error, I18n.t('csv.student_to_grader'))
    else
      result = MarkusCSV.parse(
          params[:grader_mapping].read,
          encoding: params[:encoding]) do |row|
        raise CSVInvalidLineError if row.empty?
        grade_entry_student =
            GradeEntryStudent.joins(:user)
                             .find_by(
                               users: { user_name: row.first },
                               grade_entry_form_id:
                                 params[:grade_entry_form_id])
        raise CSVInvalidLineError if grade_entry_student.nil?
        grade_entry_student.add_tas_by_user_name_array(row.drop(1))
      end
      unless result[:invalid_lines].empty?
        flash_message(:error, result[:invalid_lines])
      end
      unless result[:valid_lines].empty?
        flash_message(:success, result[:valid_lines])
      end
    end
    redirect_to action: 'index', grade_entry_form_id: params[:grade_entry_form_id]
  end

  # Download grader/student mappings in CSV format.
  def download_grader_students_mapping
    grade_entry_form = GradeEntryForm.find(params[:grade_entry_form_id])
    students = students_with_assoc

    file_out = MarkusCSV.generate(students) do |student|
      # csv format is student_name, ta1_name, ta2_name, ... etc
      student_array = [student.user_name]
      grade_entry_student = student.grade_entry_students.find_by(
        grade_entry_form_id: grade_entry_form.id)
      unless grade_entry_student.nil?
        student_array.concat(grade_entry_student
                               .tas.order(:user_name).pluck(:user_name))
      end
      student_array
    end

    send_data(file_out, type: 'text/csv', disposition: 'attachment')
  end

  # These actions act on all currently selected graders & students
  def assign_all
    @grade_entry_form = GradeEntryForm.find(params[:grade_entry_form_id])
    student_ids = params[:students]
    grader_ids = params[:graders]

    if params[:students].nil? || params[:students].empty?
      flash_now(:error, t('groups.select_a_student'))
      head :bad_request
      return
    end

    if params[:graders].nil? || params[:graders].empty?
      flash_now(:error, t('assignment.group.select_a_grader'))
      head :bad_request
      return
    end

    GradeEntryStudent.assign_all_tas(student_ids, grader_ids, @grade_entry_form)
    head :ok
  end

  def unassign_all
    @grade_entry_form = GradeEntryForm.find(params[:grade_entry_form_id])
    student_ids = params[:students]
    grader_ids = params[:graders]

    if params[:students].nil? || params[:students].empty?
      flash_now(:error, t('groups.select_a_student'))
      head :bad_request
      return
    end

    if params[:graders].nil? || params[:graders].empty?
      flash_now(:error, t('assignment.group.select_a_grader'))
      head :bad_request
      return
    end

    GradeEntryStudent.unassign_tas(student_ids, grader_ids, @grade_entry_form)
    head :ok
  end

  def unassign_single
    @grade_entry_form = GradeEntryForm.find(params[:grade_entry_form_id])

    if params[:student_id].nil?
      flash_now(:error, t('groups.select_a_student'))
      head :bad_request
      return
    end

    if params[:grader_user_name].nil?
      flash_now(:error, t('assignment.group.select_a_grader'))
      head :bad_request
      return
    end

    student_ids = [params[:student_id]]
    grader_ids = [Ta.find_by(user_name: params[:grader_user_name]).id]
    GradeEntryStudent.unassign_tas(student_ids, grader_ids, @grade_entry_form)
    head :ok
  end

  # These actions act on all currently selected graders & students
  def randomly_assign
    @grade_entry_form = GradeEntryForm.find(params[:grade_entry_form_id])
    student_ids = params[:students]
    grader_ids = params[:graders]

    if params[:students].nil? || params[:students].empty?
      flash_now(:error, t('groups.select_a_student'))
      head :bad_request
      return
    end

    if params[:graders].nil? || params[:graders].empty?
      flash_now(:error, t('assignment.group.select_a_grader'))
      head :bad_request
      return
    end

    GradeEntryStudent.randomly_assign_tas(student_ids, grader_ids, @grade_entry_form)
    head :ok
  end

  private

  def students_with_assoc
    Student.includes(
      :section,
      grade_entry_students: { grade_entry_student_tas: 'ta' }
    )
  end
end
