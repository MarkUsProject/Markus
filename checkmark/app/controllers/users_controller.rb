require 'csv'

class UsersController < ApplicationController

  def index
    # URL mapping: /users/:type/:action; see /config/routes.rb
    # i.e. :type defined via URL
    if params[:role] == User::TA then
      @users = User.tas;
    end
    if params[:role] == User::STUDENT then
      @users = User.students;
    end
  end
  
  def edit
    # dynamic find_by_<attribute name> in ActiveRecords
    @user = User.find_by_id(params[:id]) 
    update_user if request.post?
  end
  
  # Creates a new ta; handles both page display
  # of creating a TA and processing the form
  def create
    return unless request.post?
    # Default attributes: role = TA or role = STUDENT
    # params[:user] is a hash of values passed to the controller 
    # by the HTML form with the help of ActiveView::Helper::
    if params[:user][:role] == User::TA
      attrs = params[:user].merge(User.get_default_ta_attrs)
    end
    if params[:user][:role] == User::STUDENT
      attrs = params[:user].merge(User.get_default_student_attrs)
    end
    @user = User.new(attrs)
    # Return unless the save is successful; save inherted from
    # active records--creates a new record if the model is new, otherwise
    # updates the existing record
    return unless @user.save
    redirect_to :action => 'index' # Redirect 
  end

  # Update the student/TA list via CSV upload
  def update_userlist
    
    if request.post? && !params[:userlist].blank?
     
      num_update = 0
      
      flash[:invalid_lines] = []  # store lines that were not processed
      
      # read each line of the file and update classlist
      CSV::Reader.parse(params[:userlist]) do |row|
        # don't know how to fetch line so we concat given array
        next if CSV.generate_line(row).strip.empty?
        if add_user(row) == nil
          flash[:invalid_lines] << row.join(",")
        else
          num_update += 1
        end
      end # end prase
      
      flash[:upload_notice] = "#{num_update} user(s) added/updated."
      
    end
    
    redirect_to :action => 'index'
    
  end
  
  protected

  # TODO Attributes should be dynamically transformed to symbols
  # check db/schema.rb first to get current fields
  FIELDS = [:user_name, :user_number, :last_name, :first_name]

  # Creates or updates a user given the values hashed with FIELDS in 
  # the same specific order.  Returns nil if user has not been created or 
  # updated
  def add_user(values)

    # convert each line to a hash with FIELDS as corresponding keys
    # and create or update a user with the hash values
    return nil if values.length < FIELDS.length

    if params[:role] == User::TA
      attr = User.get_default_ta_attrs
    end
    if params[:role] == User::STUDENT
      attr = User.get_default_student_attrs
    end

    # FIELDS.zip(values) => [[:user_name, _], [:user_number, _], [:last_name, _], [:first_name, _]]
    # Loop through the resulting array as key, value pairs
    FIELDS.zip(values) do |key, val|
      # append them to the hash that is returned by User.get_default_ta/student_attrs
      attr[key] = val unless val.blank?
    end
    
    User.update_on_duplicate(attr)
    
  end

    protected
  
  # Update information for an individual TA or STUDENT
  def update_user

    # param object:
    # { "action" => "<controller action form invokes e.g. create>", 
    #   "controller" => "<controller e.g. persons>", 
    #   "<model e.g. person>" => { "<input name>" => "<input value>",
    #                              "<input name>" => "<input value>" } }
    
    # params[:user][:id] indexing the <model><input name>
    @user = User.find_by_id(params[:id])
    if @user.ta?
      attrs = params[:user].merge(User.get_default_ta_attrs)
    end
    if @user.student?
      attrs = params[:user].merge(User.get_default_student_attrs)
    end

    # update_attributes supplied by ActiveRecords
    return unless @user.update_attributes(attrs)
    
    flash[:edit_notice] = @user.user_name + " has been updated."
    redirect_to :action => 'index'
    
  end
   
end
