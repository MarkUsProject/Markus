require 'lib/repo/repository_factory'

 class AssignmentsController < ApplicationController
  before_filter      :authorize_only_for_admin, :except =>
  [:file_manager, :index, :download, :student_interface, :hand_in, :update_files]

  auto_complete_for :assignment, :name
  # Publicly accessible actions ---------------------------------------
  
  # Tentatively, "file_manager" is the method that displays to students the
  # interface for uploading/viewing their files for a particular assignment.
  
  # TODO: Security-wise, I'm not sure if its wise to put this in here - sure,
  # we're using before_filter, but I'm still a bit uneasy putting something a
  # student uses to upload files, in the same controller that lets instructors
  # modify assignments.  Maybe I'm just being paranoid, here.  --c6conley
  def file_manager
    @assignment = Assignment.find(params[:id])
    @grouping = current_user.accepted_grouping_for(@assignment.id)
    user_group = @grouping.group
    revision_number = params[:revision_number]
    path = params[:path] || '/'
    repo = Repository.create(REPOSITORY_TYPE).open(File.join(REPOSITORY_STORAGE, user_group.repository_name))
    if revision_number.nil?
      @revision = repo.get_latest_revision
    else
      @revision = repo.get_revision(revision_number.to_i)
    end
    @directories = @revision.directories_at_path(File.join(@assignment.repository_folder, path))
    @files = @revision.files_at_path(File.join(@assignment.repository_folder, path))
    @missing_assignment_files = []
    @assignment.assignment_files.each do |assignment_file|
      if !@revision.path_exists?(File.join(@assignment.repository_folder, assignment_file.filename))
        @missing_assignment_files.push(assignment_file)
      end
    end

  end
  
  # controller handles transactional submission of files
  def update_files
    assignment_id = params[:id]
    assignment = Assignment.find(assignment_id)
    path = params[:path] || '/'
    grouping = current_user.accepted_grouping_for(assignment_id)
    if !grouping.is_valid?
      redirect_to :action => :file_manager, :id => assignment_id
      return
    end
    user_group = grouping.group
    repo = Repository.create(REPOSITORY_TYPE).open(File.join(REPOSITORY_STORAGE, user_group.repository_name))
       
    assignment_folder = File.join(assignment.repository_folder, path)
    
    # Get the revision numbers for the files that we've seen - these
    # values will be the "expected revision numbers" that we'll provide
    # to the transaction to ensure that we don't overwrite a file that's
    # been revised since the user last saw it.
    file_revisions = params[:file_revisions].nil? ? [] : params[:file_revisions]
    
    # The files that will be replaced - just give an empty array
    # if params[:replace_files] is nil
    replace_files = params[:replace_files].nil? ? {} : params[:replace_files]

    # The files that will be deleted
    delete_files = params[:delete_files].nil? ? {} : params[:delete_files]

    # The files that will be added
    new_files = params[:new_files].nil? ? {} : params[:new_files]
    
    # Create transaction, setting the author.  Timestamp is implicit.
    # TODO: change to cdf-id for author-param
    txn = repo.get_transaction(current_user.user_name)

    # delete files marked for deletion
    delete_files.keys.each do |filename|
      txn.remove(File.join(assignment_folder, filename), file_revisions[filename])
    end
    
    # Replace files
    replace_files.each do |filename, file_object|
      txn.replace(File.join(assignment_folder, filename), file_object.read, file_revisions[filename])
    end

    
    # Add new files
    new_files.each do |file_object|
      txn.add(File.join(assignment_folder, file_object.original_filename), file_object.read)
    end

    # finish transaction
    if !txn.has_jobs?
      flash[:transaction_warning] = "No actions were detected in the last submit.  Nothing was changed."
      redirect_to :action => "file_manager", :id => assignment_id
      return
    end
    if !repo.commit(txn)
      flash[:update_conflicts] = txn.conflicts
    end
    redirect_to :action => "file_manager", :id => assignment_id
  end
  
  def hand_in
    @assignment = Assignment.find(params[:id])
    student = Student.find(session[:uid])
    grouping = student.accepted_grouping_for(@assignment.id)
    # If this Grouping is invalid, they cannot hand in...
    if !grouping.is_valid?
      redirect_to :action => :file_manager, :id => assignment_id
      return
    end
    
    time = Time.now
    Submission.create_by_timestamp(grouping,time)
    flash[:submit_notice] = "Submission saved"
     redirect_to :action => "file_manager", :id => @assignment.id
  end
   
  # student interface to manage their assignments

  def student_interface
     @assignment = Assignment.find(params[:id])
     @student = Student.find(session[:uid]) 
     @grouping = @student.accepted_grouping_for(@assignment.id)

     if @student.has_pending_groupings_for?(@assignment.id)
       @pending_grouping = @student.pending_groupings_for(@assignment.id) 
     end

     if @grouping.nil?
       if @assignment.group_max == 1
          @student.create_group_for_working_alone_student(@assignment.id)
         redirect_to :action => 'student_interface', :id => @assignment.id
       else
         render :action => 'student_interface', :layout => 'no_menu_header'
         return
       end
     end
     
     if !@grouping.nil?
       # We look for the informations on this group
       # The members
       @studentmemberships =  @grouping.student_memberships
       # The group name
       @group = @grouping.group
       # The inviter
       
       @inviter = @grouping.inviter
     end
  end


  def download
    file_name = params[:file_name]
    path = params[:path] || '/'
    assignment_id = params[:id]
    assignment = Assignment.find(assignment_id)
    assignment_folder = assignment.repository_folder
    user_group = current_user.accepted_grouping_for(assignment_id).group
    repo = Repository.create(REPOSITORY_TYPE).new(File.join(REPOSITORY_STORAGE, user_group.repository_name))
    revision = repo.get_latest_revision
    file = revision.files_at_path(File.join(assignment_folder, path))[file_name]
    if file.nil?
      @file_contents = "Could not find the file #{file_name} in the repository for group #{user_group.group_name} for revision #{revision.revision_number}"
    else
      @file_contents = repo.download(file)
    end
    # Blast the file contents
    send_data @file_contents, :type => 'text/plain', :disposition => 'inline', :filename => file_name
  end
  
  # Displays "Manage Assignments" page for creating and editing 
  # assignment information
  def index
    @assignments = Assignment.all(:order => :id)
    if current_user.student?
      render :action => "student_assignment_list"
    end
    render :action => 'index', :layout => 'sidebar'
  end
  
  def edit
    @assignment = Assignment.find_by_id(params[:id])
    # TODO Code below is only temporary for migration
    # delete when all assignments have submission rules
    unless @assignment.submission_rule
      @assignment.submission_rule = SubmissionRule.new
      @assignment.student_form_groups = true  # default value
      @assignment.save
    end
  end
  

  
  # Ajax support for adding another file text field for this assignment
  def add_assignment_file
    @assignment = Assignment.find(params[:id])
    new_assignment_file_name = params[:new_assignment_filename]
    # Check to see if a file with this filename already exists
    exist_filename = @assignment.assignment_files.find_by_filename(new_assignment_file_name)
    if exist_filename
      render :update do |page|
        page.visual_effect :highlight, "assignment_file_#{exist_filename.id}"
      end
      return
    end
    @assignment_file = AssignmentFile.new
    @assignment_file.assignment = @assignment
    @assignment_file.filename = params[:new_assignment_filename]
    @assignment_file.save
    render :update do |page|
      page.insert_html :bottom, :files, :partial => 'file_fields', :locals => {:assignment_file => @assignment_file}
    end
  end
  
  def remove_assignment_file
    if request.post?
      assignment_file = AssignmentFile.find(params[:id])
      assignment_file.destroy
      render :update do |page|
        page.remove "assignment_file_#{assignment_file.id}"
      end
    end
  end
  

  # Form accessible actions --------------------------------------------
  # Post actions that we expect only forms to access them
  
  # Called when form for creating a new assignment is submitted
  def new
    @assignments = Assignment.all
    if !request.post?
      render :action => 'new', :layout => 'no_menu_header'
      return
    end
    @assignment = Assignment.new(params[:assignment])
    @assignment.transaction do
      if !@assignment.save
        render :action => :new, :layout => 'no_menu_header'
        return
      end
      if params[:assignment_files]
        params[:assignment_files].each do |assignment_file_name|
          if !assignment_file_name.empty?
            assignment_file = AssignmentFile.new(:filename => assignment_file_name, :assignment => @assignment)
            assignment_file.save
          end
        end
      end
      if params[:persist_groups_assignment]
        @assignment.clone_groupings_from(params[:persist_groups_assignment])
      end
      if @assignment.group_max == 1
        @assignment.create_groupings_when_students_work_alone
      end
      @assignment.save
    end
    redirect_to :action => "edit", :id => @assignment.id
  end
  
  def update_group_properties_on_persist
    assignment = Assignment.find(params[:assignment_id])
    render :update do |page|
      page.call "update_group_properties", (assignment.group_max != 1), assignment.student_form_groups, assignment.group_min, assignment.group_max, assignment.group_name_autogenerated
      
    end
  end
  
  # Called when form for updating existing assignment is submitted
  def update
    return unless request.post?
    
    @assignment = Assignment.find_by_id(params[:id])
    @assignment.attributes = params[:assignment]
    
    rules = @assignment.submission_rule
    # must be explicitly assigned, due to method conflict for "type"
    rules[:type] = params[:submission_rule][:type]
    rules.attributes = params[:submission_rule]
        
    # Go back to "Edit assignment" page if unable to save
    if (@assignment.save && @assignment.assignment_files.each(&:save) && rules.save)
      redirect_to :action => 'edit', :id => @assignment.id
    else
      render :action => 'edit'
    end
    end

  def use_another_assignment_groups
    render :update do |page|
      page.visual_effect(:appear, "other_assignment_groups", :duration => 0.5)
      page.visual_effect(:fade, "group_choice", :duration => 0.5)
    end
  end

  def new_group_properties
    render :update do |page|
         page.visual_effect(:appear, "group_properties", :duration => 0.5)
         page.visual_effect(:fade, "group_choice", :duration => 0.5)
     end    
  end


  def cancel
    render :update do |page|
         page.visual_effect(:fade, "group_properties", :duration => 0.5)
         page.visual_effect(:appear, "group_choice", :duration => 0.5)
         page.visual_effect(:fade, "other_assignment_groups", :duration => 0.5)
     end
    

  end

  private
  
  # determine if filename is in old_file_list
  def is_new_file(old_files_list, filename)
    return old_files_list.find(filename).none?
  end
  
  def base_part_of(filename)
    File.basename(filename).gsub(/[^\w._-]/, '')  
  end
  
  def get_file_contents(multipart, filename)
    multipart.each do |f|
      if filename == base_part_of(f.original_filename)
        return f.read
      end
    end
  end
end
