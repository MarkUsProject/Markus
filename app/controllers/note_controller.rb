class NoteController < ApplicationController
 before_filter :authorize_for_ta_and_admin
  
  def notes_dialog
    @assignment = Assignment.find(params[:id])
    @cls = params[:noteable_type]
    @noteable = Kernel.const_get(@cls).find_by_id(params[:noteable_id])
    @cont = params[:controller_to]
    @action = params[:action_to]
    @notes = Note.find(:all, :conditions => { :noteable_id => @noteable.id, :noteable_type => @noteable.class.model_name})
    render :partial => "notes/modal_dialogs/notes_dialog.rjs"
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

end