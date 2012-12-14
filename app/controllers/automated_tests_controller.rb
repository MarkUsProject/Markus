# The actions necessary for managing the Testing Framework form
require 'helpers/ensure_config_helper.rb'

class AutomatedTestsController < ApplicationController
  include AutomatedTestsHelper

  before_filter      :authorize_only_for_admin,
                     :only => [:manage, :update]
  before_filter      :authorize_for_user,
                     :only => [:index]
                     
  def index                               
    submission_id = params[:submission_id]
    
    # TODO: call_on should be passed to index as a parameter. 
    list_call_on = %w(submission request collection)
    call_on = list_call_on[0]
    
    AutomatedTestsHelper.request_a_test_run(submission_id, 'collection', @current_user)
    
    # TODO: render a new page
    #render :test_replace,
    #       :locals => {:test_result_files => @test_result_files,
    #                   :result => @result}
  end
  
  #Update is called when files are added to the assigment
  def update
      @assignment = Assignment.find(params[:assignment_id])

      #perform transaction, if errors, none of new config saved
      @assignment.transaction do

        begin
          # Process testing framework form for validation
          @assignment = process_test_form(@assignment, params)
        rescue Exception, RuntimeError => e
          @assignment.errors.add(:base, I18n.t("assignment.error",
                                               :message => e.message))
          render :manage
          return        
        end

        # Save assignment and associated test files
        if @assignment.save
          flash[:success] = I18n.t("assignment.update_success")
          redirect_to :action => 'manage',
                      :assignment_id => params[:assignment_id]
        else
          render action => :manage
        end
     end
  end

  # Manage is called when the Test Framework UI is loaded
  def manage
    @assignment = Assignment.find(params[:assignment_id])

    #this is breaking, not actually doing anything so commenting
    #out for now
    # Create test scripts for testing if no script is available
    #if @assignment && @assignment.test_scripts.empty?
     # create_test_scripts(@assignment)
    #end
    
  end

end
