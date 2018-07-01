class NotesController < ApplicationController
  before_action :authorize_for_ta_and_admin
  before_action :ensure_can_modify, only: [:edit, :update]

  # TODO this method needs explaining ! What is return_id ?
  def notes_dialog
    @return_id = params[:id]
    @cls = params[:noteable_type]
    @noteable = Kernel.const_get(@cls).find_by_id(params[:noteable_id])
    @cont = params[:controller_to]
    @action = params[:action_to]
    @highlight_field = params[:highlight_field]
    @number_of_notes_field = params[:number_of_notes_field]

    @notes = Note.where(noteable_id: @noteable.id, noteable_type: @noteable.class.name)

    render partial: 'notes/modal_dialogs/notes_dialog_script',
      formats: [:js], handlers: [:erb]
  end

  def add_note
    return unless request.post?
    @note = Note.new
    @note.creator_id = @current_user.id
    @note.notes_message = params[:new_notes]
    @note.noteable_id = params[:noteable_id]
    @note.noteable_type = params[:noteable_type]
    unless @note.save
      render 'notes/modal_dialogs/notes_dialog_error',
        formats: [:js], handlers: [:erb]
    else
      @note.reload
      @number_of_notes_field = params[:number_of_notes_field]
      @highlight_field = params[:highlight_field]
      @number_of_notes = @note.noteable.notes.size
      render 'notes/modal_dialogs/notes_dialog_success',
        formats: [:js], handlers: [:erb]
    end
  end

  def index
    @notes = Note.includes(:user, :noteable).order(created_at: :desc)
    @current_user = current_user
    # Notes are attached to noteables, if there are no noteables, we can't make notes.
    @noteables_available = Note.noteables_exist?
		render 'index', formats: [:html]
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
    @note.creator_id = @current_user.id

    if @note.save
      flash_message(:success, I18n.t('notes.create.success'))
      redirect_to action: 'index'
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
        @students = Student.order(:user_name)
      when 'Assignment'
        @assignments = Assignment.all
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
		render 'edit', formats: [:html], handlers: [:erb]
  end

  def update
    if @note.update_attributes(notes_params)
      flash_message(:success, I18n.t('notes.update.success'))
      redirect_to action: 'index'
    else
      render 'edit', formats: [:html], handlers: [:erb]
    end
  end

  def destroy
    @note = Note.find(params[:id])
    if @note.user_can_modify?(current_user)
      @note.destroy
      flash_message(:success, I18n.t('notes.delete.success'))
    else
      flash_message(:error, I18n.t('notes.delete.error_permissions'))
    end
	  render 'destroy', formats: [:js], handlers: [:erb]
  end

  private

    def retrieve_groupings(assignment)
      if assignment.nil?
        @groupings = Array.new
        return
      end
      @groupings = Grouping.includes(:group, student_memberships: :user).where(assignment_id: assignment.id)
    end

    def new_retrieve
      @assignments = Assignment.all
      retrieve_groupings(@assignments.first)
    end

    # Renders a 404 error if the current user can't modify the given note.
    def ensure_can_modify
      @note = Note.find(params[:id])

      unless @note.user_can_modify?(current_user)
        render 'shared/http_status', formats: [:html], status: 404,
          layout: false, locals: {
            code: '404', message: HttpStatusHelper::ERROR_CODE['message']['404']
          }
      end
    end

  def notes_params
    params.require(:note).permit(:notes_message, :noteable_id)
  end
end
