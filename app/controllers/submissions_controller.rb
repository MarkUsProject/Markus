class SubmissionsController < ApplicationController
  include SubmissionsHelper
  
  before_filter    :authorize_only_for_admin, :except => [:browse, :index]
  before_filter    :authorize_for_ta_and_admin, :only => [:browse, :index]
  
  
  def browse
    @assignment = Assignment.find(params[:id])
    # If the current user is a TA, then we need to get the Groupings
    # that are assigned for them to mark.  If they're an Admin, then
    # we need to give them a list of all Groupings for this Assignment.
    if current_user.ta?
      @groupings = []
      @assignment.ta_memberships.find_all_by_user_id(current_user.id).each do |membership|
        @groupings.push(membership.grouping)
      end
      render :action => 'ta_browse'
      return
    end
    
    if current_user.admin?
      @groupings = @assignment.groupings
      render :action => 'admin_browse'
      return 
    end
  end
  
  def index
    @assignments = Assignment.all(:order => :id)
  end
  
  def create_manually
    grouping = Grouping.find(params[:grouping_id])
    assignment_id = params[:id]
    time = Time.now
    Submission.create_by_timestamp(grouping, time)
    redirect_to :action => 'browse', :id => assignment_id
  end
  
  def update_submissions
    return unless request.post?
    if params[:release_results]
      params[:groupings].each do |grouping_id|
        grouping = Grouping.find(grouping_id)
        if !grouping.has_submission?
          # TODO:  Neaten this up...
          render :text => "Grouping ID:#{grouping_id} had no submission"
          return
        end
        submission = grouping.get_submission_used
        if !submission.has_result?
          # TODO:  Neaten this up...
          render :text => "Grouping ID:#{grouping_id} had no result"
          return       
        end
        result = submission.result
        result.released_to_students = true
        result.save
      end
    end
    redirect_to :action => 'browse', :id => params[:id]
  end

  
#  # Handles file submissions for a form POST, 
#  # or displays submission page for the user
#  def submit
#    @assignment = Assignment.find(params[:id])
#    sub_time = Time.now  # submission timestamp for submitted files
#    return unless validate_submit(@assignment, sub_time)
#    submission = @assignment.submission_by(current_user)
#   flash[:upload] =  { :success => [], :fail => [] }
#    
#    # process upload
#    if (request.post? && params[:files])
#      # handle late submissions
#      if @assignment.due_date < sub_time
#        rule = @assignment.submission_rule || NullSubmissionRule.new
#        rule.handle_late_submission(submission)
#      end
#      
#      # do file upload
#      params[:files].each_value do |file|
#        f = file[:file]
#        unless f.blank?
#          subfile = submission.submit(current_user, f, sub_time)
#          if subfile.valid?
#            flash[:upload][:success] << subfile.filename
#          else
#            flash[:upload][:fail] << subfile.filename
#          end
#        end
#      end
#    end
#      
#    # display submitted filenames, including unsubmitted required files
#     @files = submission.submitted_filenames || []
#  end
#  
#  
#  # Handles file viewing submitted by the user or group
#  def view
#    @assignment = Assignment.find(params[:id])
#    submission = @assignment.submission_by(current_user)
#    
#    # check if user has a submitted file by that filename
#    subfile = submission.submission_files.find_by_filename(params[:filename])
#    dir = submission.submit_dir
#    filepath = File.join(dir, params[:filename])
#    
#    if subfile && File.exist?(filepath)
#      send_file filepath, :type => 'text/plain', :disposition => 'inline'
#    else
#      render :text => "File not found", :membership_status => 401
#    end
#  end
#  
#  # Moves a deleted file to a backup folder
#  def remove_file
#    return unless request.delete?
#    # delete file
#    assignment = Assignment.find(params[:id])
#    submission = assignment.submission_by(current_user)
#    submission.remove_file(params[:filename])

#    # check if deleted file is a required file
#    @reqfiles = assignment.assignment_files.map { |af| af.filename } || []
#    render :update do |page|
#      page["filename_#{params[:filename]}"].remove
#      if @reqfiles.include? params[:filename]
#        page.insert_html :after, "table_heading", :partial => 'required_file'
#      end
#    end
#  end
#  
  
end
