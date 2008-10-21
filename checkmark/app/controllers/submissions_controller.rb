class SubmissionsController < ApplicationController
  include SubmissionsHelper
  
  def index
    @assignments = Assignment.all(:order => :id)
  end
  
  # Handles file submissions for a form POST, 
  # or displays submission page for the user
  def submit
    @assignment = Assignment.find(params[:id])
    return unless validate_submit(@assignment)
    submission = @assignment.submission_by(current_user)
    
    if request.post?  # process upload
      flash[:upload] =  { :success => [], :fail => [] }
      sub_time = Time.now  # submission timestamp for all files
      
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
      end if params[:files]
    end
    # display submitted filenames, including unsubmitted required files
    @files = submission.submitted_filenames || []
  end
  
  # TODO FOR DEMO PURPOSES ONLY
  # Handles file submissions for a form POST, 
  # or displays submission page for the user
  def submit_sample
    @assignment = Assignment.find(params[:id])
    return unless validate_submit(@assignment)
    submission = @assignment.submission_by(current_user)
    
    if request.post?  # process upload
      flash[:upload] =  { :success => [], :fail => [] }
      sub_time = Time.now  # submission timestamp for all files
      
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
      end if params[:files]
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
  
  # AJAX handlers
  def remove_file
    if request.delete?
      # TODO delete file
      # check if deleted file is a required file
      
    end
  end
  
  
end
