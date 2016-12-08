# Manages actions relating to assigning graders.
class MarksGradersController < ApplicationController
  include MarksGradersHelper

  before_filter :authorize_only_for_admin

  layout 'assignment_content'

  def populate
    @grade_entry_form = GradeEntryForm.find(params[:grade_entry_form_id])
    @students = students_with_assoc
    @sections = Section.order(:name)
    mgsti = get_marks_graders_student_table_info(@students,
                                                 @grade_entry_form)
    render json: [mgsti, @sections]
  end

  def populate_graders
    @grade_entry_form = GradeEntryForm.find(params[:grade_entry_form_id])
    render json: get_marks_graders_table_info(@grade_entry_form)
  end

  def index
    @grade_entry_form = GradeEntryForm.find(params[:grade_entry_form_id])
    @section_column = ''
    if Section.all.size > 0
      @section_column = "{
          id: 'section',
          content: '#{I18n.t(:'user.section')}',
          sortable: true},"
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
  def global_actions
    @grade_entry_form = GradeEntryForm.find(params[:grade_entry_form_id])
    student_ids = params[:students]
    grader_ids = params[:graders]

    case params[:current_table]
      when 'groups_table'
        if params[:students].nil? || params[:students].size == 0
         # If there is a global action than there should be a student selected
          if params[:global_actions]
            flash_now(:error, t('assignment.group.select_a_student'))
            head 400
            return
          end
        end

        case params[:global_actions]
        when 'assign'
          if params[:graders].nil? || params[:graders].size == 0
            flash_now(:error, t('assignment.group.select_a_grader'))
            head 400
            return
          end
          assign_all_graders(student_ids, grader_ids, @grade_entry_form)
          return
        when 'unassign'
          unassign_graders(params[:gests])
          return
        when 'random_assign'
          if params[:graders].nil? or params[:graders].size ==  0
            flash_now(:error, t('assignment.group.select_a_grader'))
            head 400
            return
          end
          randomly_assign_graders(student_ids, grader_ids, @grade_entry_form)
          return
        end
    end
  end

  private

  def students_with_assoc
    Student.includes(
      :section,
      grade_entry_students: { grade_entry_student_tas: 'ta' })
  end

  def randomly_assign_graders(student_ids, grader_ids, form)
    GradeEntryStudent.randomly_assign_tas(student_ids, grader_ids, form)
    render nothing: true
  end

  def assign_all_graders(student_ids, grader_ids, form)
    GradeEntryStudent.assign_all_tas(student_ids, grader_ids, form)
    render nothing: true
  end

  def unassign_graders(gest_ids)
    GradeEntryStudent.unassign_tas(gest_ids)
    render nothing: true
  end
end
