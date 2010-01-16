class NoteController < ApplicationController
  before_filter :authorize_for_ta_and_admin
  before_filter :ensure_can_modify, :only => [:edit, :update]
  
  def notes_dialog
    @assignment = Assignment.find(params[:id])
    @cls = params[:noteable_type]
    @noteable = Kernel.const_get(@cls).find_by_id(params[:noteable_id])
    @cont = params[:controller_to]
    @action = params[:action_to]
    @notes = Note.find(:all, :conditions => { :noteable_id => @noteable.id, :noteable_type => @noteable.class.model_name})
    render :partial => "note/modal_dialogs/notes_dialog.rjs"
  end
  
  def add_note
    return unless request.post?
    note = Note.new
    note.creator_id = @current_user.id
    note.notes_message = params[:new_notes]
    @cls = params[:noteable_type]
    @noteable = Kernel.const_get(@cls).find_by_id(params[:noteable_id])
    note.noteable = @noteable
    result = note.save
    redirect_to :controller => params[:controller_to], :action => params[:action_to], :id => params[:id] , :success => result
  end
  
  def index
    @notes = Note.find(:all, :order => "created_at DESC", :include => [:user, :noteable])
    @current_user = current_user
    # Notes are attached to groupings, if there are no groupings, we can't make notes.
    @groupings_available = !(Grouping.all.empty?)
  end
  
  def new
    new_retrieve
  end
  
  def create
    return unless request.post?
    
    @note = Note.new(params[:note])
    @note.noteable_type = 'Grouping'
    @note.creator_id = @current_user.id
    
    if @note.save
      flash[:success] = I18n.t('notes.create.success')
      redirect_to :action => 'index'
    else
      new_retrieve
      render :action => "new"
    end
  end
  
  # Used to update the values in the groupings dropdown in the new note form
  def new_update_groupings
    retrieve_groupings(Assignment.find(params[:assignment_id]))
  end
  
  def edit
  end
  
  def update
    return unless request.post?
    
    if @note.update_attributes(params[:note])
      flash[:success] = I18n.t('notes.update.success')
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end
  
  def delete
    return unless request.delete?
    
    @note = Note.find(params[:id])
    if @note.user_can_modify?(current_user)
      @note.destroy
      flash[:success] = I18n.t('notes.delete.success')
    else
      flash[:error] = I18n.t('notes.delete.error_permissions')
    end
  end
  
  private
    def retrieve_groupings(assignment)
      if assignment.nil?
        @groupings = Array.new
        return
      end
      @groupings = Grouping.find_all_by_assignment_id(assignment.id, :include => [:group, {:student_memberships => :user}])
    end
  
    def new_retrieve
      @assignments = Assignment.all
      retrieve_groupings(@assignments.first)
    end
    
    # Renders a 404 error if the current user can't modify the given note.
    def ensure_can_modify
      @note = Note.find(params[:id])
      
      unless @note.user_can_modify?(current_user)
        render :file => "#{RAILS_ROOT}/public/404.html",  
          :status => 404
        return
      end
    end

end