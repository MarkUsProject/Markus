class SubmissionsController < ApplicationController
  include SubmissionsHelper
  
  def index
    @assignments = Assignment.all(:order => :id)
  end
  
  # Handles file submissions for a form POST, 
  # or displays submission page for the user
  def submit
    @assignment = Assignment.find(params[:id])
    sub_time = Time.now  # submission timestamp for submitted files
    return unless validate_submit(@assignment, sub_time)
    submission = @assignment.submission_by(current_user)
    flash[:upload] =  { :success => [], :fail => [] }
    
    # process upload
    if (request.post? && params[:files])
      # handle late submissions
      if @assignment.due_date < sub_time
        rule = @assignment.submission_rule || NullSubmissionRule.new
        rule.handle_late_submission(submission)
      end
      
      # do file upload
      params[:files].each_value do |file|
        f = file[:file]
        unless f.blank?
          subfile = submission.submit(current_user, f, sub_time)
          if subfile.valid?
            flash[:upload][:success] << subfile.filename
          else
            flash[:upload][:fail] << subfile.filename
          end
        end
      end
    end
      
    # display submitted filenames, including unsubmitted required files
    @files = submission.submitted_filenames || []
  end
  
  
  # Handles file viewing submitted by the user or group
  def view
    @assignment = Assignment.find(params[:id])
    submission = @assignment.submission_by(current_user)
    
    # check if user has a submitted file by that filename
    subfile = submission.submission_files.find_by_filename(params[:filename])
    dir = submission.submit_dir
    filepath = File.join(dir, params[:filename])
    
    if subfile && File.exist?(filepath)
      send_file filepath, :type => 'text/plain', :disposition => 'inline'
    else
      render :text => "File not found", :status => 401
    end
  end
  
  # Moves a deleted file to a backup folder
  def remove_file
    return unless request.delete?
    # delete file
    assignment = Assignment.find(params[:id])
    submission = assignment.submission_by(current_user)
    submission.remove_file(params[:filename])

    # check if deleted file is a required file
    @reqfiles = assignment.assignment_files.map { |af| af.filename } || []
    render :update do |page|
      page["filename_#{params[:filename]}"].remove
      if @reqfiles.include? params[:filename]
        page.insert_html :after, "table_heading", :partial => 'required_file'
      end
    end
  end
  
  
end
