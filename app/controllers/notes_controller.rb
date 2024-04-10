class NotesController < ApplicationController
  before_action { authorize! }
  responders :flash, :collection

  def notes_dialog
    @cls = params[:noteable_type]
    @cont = params[:controller_to]
    @action = params[:action_to]
    @highlight_field = params[:highlight_field]
    @number_of_notes_field = params[:number_of_notes_field]

    @notes = Note.where(noteable_id: noteable.id, noteable_type: noteable.class.name)

    render partial: 'notes/modal_dialogs/notes_dialog_script',
           formats: [:js], handlers: [:erb]
  end

  def add_note
    return unless request.post?
    @note = Note.new
    @note.creator_id = current_role.id
    @note.notes_message = params[:new_notes]
    @note.noteable = noteable
    if @note.save
      @note.reload
      @number_of_notes_field = params[:number_of_notes_field]
      @highlight_field = params[:highlight_field]
      @number_of_notes = @note.noteable.notes.size
      render 'notes/modal_dialogs/notes_dialog_success',
             formats: [:js], handlers: [:erb]
    else
      render 'notes/modal_dialogs/notes_dialog_error',
             formats: [:js], handlers: [:erb]
    end
  end

  def index
    @notes = Note.joins(:role).where('roles.course_id': current_course.id).order(created_at: :desc)
    respond_to do |format|
      format.html do
        # Notes are attached to noteables, if there are no noteables, we can't make notes.
        @noteables_available = Note.noteables_exist?(current_course.id)
        render 'index', formats: [:html]
      end

      format.json do
        notes_data = @notes.map do |note|
          {
            date: note.format_date,
            user_name: note.role.user_name,
            display_for: note.noteable.display_for_note,
            message: note.notes_message,
            id: note.id,
            modifiable: allowed_to?(:modify?, note)
          }
        end

        render json: notes_data
      end
    end
  end

  # gets the objects for groupings on first load.
  def new
    new_retrieve
    @note = Note.new
    render 'new', formats: [:html], handlers: [:erb]
  end

  def create
    @note = Note.new(notes_params)
    @note.noteable_type = params[:noteable_type]
    @note.creator_id = current_role.id

    if @note.save
      respond_with @note, location: course_notes_path(current_course)
    else
      new_retrieve
      render 'new', formats: [:html], handlers: [:erb]
    end
  end

  # Used to update the values in the groupings dropdown in the new note form
  def new_update_groupings
    retrieve_groupings(Assignment.find(params[:assignment_id]))
    render 'new_update_groupings', formats: [:js], handlers: [:erb]
  end

  # used for RJS call
  def noteable_object_selector
    case params[:noteable_type]
    when 'Student'
      @students = current_course.students.joins(:user).order(:user_name)
    when 'Assignment'
      @assignments = current_course.assignments
    when 'Grouping'
      new_retrieve
    else
      # default to groupings if all else fails.
      params[:noteable_type] = 'Grouping'
      flash_message(:error, I18n.t('notes.new.invalid_selector'))
      new_retrieve
    end
    render 'noteable_object_selector', formats: [:js], handlers: [:erb]
  end

  def edit
    @note = record
    render 'edit', formats: [:html], handlers: [:erb]
  end

  def update
    @note = record
    if @note.update(notes_params)
      respond_with @note, location: course_notes_path(current_course)
    else
      render 'edit', formats: [:html], handlers: [:erb]
    end
  end

  def destroy
    @note = record
    if flash_allowance(:error, allowance_to(:modify?, @note)).value
      @note.destroy
      respond_with @note, location: course_notes_path(current_course)
    else
      render 'destroy', formats: [:js], handlers: [:erb]
    end
  end

  private

  def retrieve_groupings(assignment)
    if assignment.nil?
      @groupings = []
      return
    end
    @groupings = assignment.groupings.includes(:group, student_memberships: :role)
  end

  def new_retrieve
    @assignments = current_course.assignments
    retrieve_groupings(@assignments.first)
  end

  def notes_params
    params.require(:note).permit(:notes_message, :noteable_id)
  end

  def noteable
    return @noteable if defined?(@noteable)
    noteable_id = params[:noteable_id] || params[:note]&.[](:noteable_id)
    return @noteable = nil unless Note::NOTEABLES.include?(params[:noteable_type])
    @noteable = Note.get_noteable(params[:noteable_type]).find_by(id: noteable_id)
  end

  protected

  # Include noteable_id param in parent_params so that check_record can ensure that
  # the noteable is in the same course as the current course
  def parent_params
    return super unless Note::NOTEABLES.include?(params[:noteable_type])
    noteable_id = params[:noteable_id] || params[:note]&.[](:noteable_id)
    return super unless noteable_id
    noteable_key = "#{params[:noteable_type].downcase}_id"
    params[noteable_key] = noteable_id
    [noteable_key, *super]
  end
end
