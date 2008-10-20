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
    # display submitted filenames
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
  
  # Shows group status and a way to invite additional members 
  # to the group for the inviter member
  def status
    action_init(params[:id])
    @members = @group.members
    
    # add additional members to the group
    return unless request.post?
    members = add_members(@group, params[:groups].values)
    if @group.errors.empty? && members.all?(&:valid?)
      redirect_to(:action => 'status', :id => @assignment.id) if members.all?(&:save)
    end
  end
  
  private
  
  # Helper method to do most common tasks for action: fetch assignment 
  # and group, and redirect to appropriate page if necessary
  def action_init(aid)
    @assignment = Assignment.find(aid)
    @group = Group.find_group(current_user, @assignment.id)
    unless @group || @assignment.individual?
      redirect_to :action => 'creategroup', :id => aid
    end
  end
  
end
