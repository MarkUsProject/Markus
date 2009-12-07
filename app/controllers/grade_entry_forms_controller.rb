# The actions necessary for managing grade entry forms.

class GradeEntryFormsController < ApplicationController
  before_filter      :authorize_only_for_admin
  
  # Create a new grade entry form
  def new
    @grade_entry_form = GradeEntryForm.new
    return unless request.post?
    
    # Process input properties
    @grade_entry_form.transaction do
      if @grade_entry_form.update_attributes(params[:grade_entry_form])
        # Success message
        flash[:success] = I18n.t('grade_entry_forms.create.success')
        redirect_to :action => "edit", :id => @grade_entry_form.id
      end
    end
  end 
  
  # Edit the properties of a grade entry form
  def edit
    @grade_entry_form = GradeEntryForm.find_by_id(params[:id])
    return unless request.post?
  
    # Process changes to input properties  
    @grade_entry_form.transaction do
      if @grade_entry_form.update_attributes(params[:grade_entry_form])
        # Success message
        flash[:success] = I18n.t('grade_entry_forms.edit.success')
        redirect_to :action => "edit", :id => @grade_entry_form.id
      end
    end
  end

end
