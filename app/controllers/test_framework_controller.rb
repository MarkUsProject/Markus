# The actions necessary for managing the Testing Framework form
class TestFrameworkController < ApplicationController
  include TestFrameworkHelper

  def manage
    @assignment = Assignment.find_by_id(params[:id])

    # Create ant test files required by Testing Framework
    create_ant_test_files(@assignment)

    if !request.post?
      return
    end

    @assignment.transaction do

      begin
        # Process testing framework form for validation
        @assignment = process_test_form(@assignment, params)
      rescue Exception, RuntimeError => e
        @assignment.errors.add_to_base(I18n.t("assignment.error", :message => e.message))
        return
      end

      # Save assignment and associated test files
      if @assignment.save
        flash[:success] = I18n.t("assignment.update_success")
        redirect_to :action => 'manage', :id => params[:id]
      else
        render :action => 'manage'
      end
    end
  end

end
