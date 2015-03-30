class KeyPairsController < ApplicationController
  # GET /key_pairs
  # GET /key_pairs.json
  def index
    @key_pairs = KeyPair.where("user_name = ?", @current_user.user_name)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @key_pairs }
    end
  end

  # GET /key_pairs/1
  # GET /key_pairs/1.json
  def show
    @key_pair = KeyPair.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @key_pair }
    end
  end

  # GET /key_pairs/new
  # GET /key_pairs/new.json
  def new
    @key_pair = KeyPair.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @key_pair }
    end
  end

  # GET /key_pairs/1/edit
  def edit
    @key_pair = KeyPair.find(params[:id])
  end

  # Given a File object to upload, save it on the file system with
  # association to the user_name given.
  # If a String is supplied as the first argument then it's content
  # is used to create the public key
  # Creates the KEY_STORAGE directory if it does not yet exist
  def upload_key_file(_file, user_name)
    Dir.mkdir(KEY_STORAGE) unless File.exists?(KEY_STORAGE)

    public_key_content = ''

    if _file.is_a? String
      # Dump the string into the file
      public_key_content = _file
    else
      public_key_content = _file.read
    end

    File.open(Rails.root.join(KEY_STORAGE, user_name + '.pub'), 'wb') do |f|
      f.write(public_key_content)
    end

    # todo: check current user to see if they have permission to
    # use a different user_name then their current one (admins)


    # Perform student key update in isolation from admins

    #$stderr.puts Membership.all(:joins => 'INNER JOIN groupings ON memberships.grouping_id = groupings.group_id AND memberships.user_id = ' + String(@current_user.id))
    #$stderr.puts Membership.all(:joins => 'INNER JOIN groupings ON memberships.grouping_id = groupings.group_id AND memberships.user_id = ' + String(@current_user.id) + ' INNER JOIN groups ON group_id = groups.id')
    # todo: get rid of all - optimize
    #@groups = Membership.where("membership_status != 'pending'").all(:joins => 'INNER JOIN groupings ON memberships.grouping_id = groupings.group_id AND memberships.user_id = ' + String(@current_user.id) + ' INNER JOIN groups ON group_id = groups.id')

    #$stderr.puts @temp.all(:joins => 'INNER JOIN groups ON group_id = groups.id')

    # uniqueness
    #@groups = @groups.uniq{|x| x.grouping.group.group_name}

    add_key(KEY_STORAGE + '/' + user_name + '.pub')

  end

  # Adds a specific public key to a specific user.
  def add_key(_path)

    #gitolite admin repo - these keys are for the repo-admin user - aka git on my machine
    settings = { :public_key => '/home/git/.ssh/id_rsa.pub', :private_key => '/home/git/.ssh/id_rsa' }
    ga_repo = Gitolite::GitoliteAdmin.new(REPOSITORY_STORAGE + '/gitolite-admin', settings)
    # The admin repo is loaded into memory
    conf = ga_repo.config

    # Check to see if an individual repo exists for this user
    #if conf.has_repo?(_username)
    key = Gitolite::SSHKey.from_file(_path)

    ga_repo.add_key(key)

    # todo: make a constant for the admin key - readd admin key
    adminKey = Gitolite::SSHKey.from_file("/home/git/git.pub")
    ga_repo.add_key(adminKey)

    # update Gitolite repo
    #ga_repo.save_and_apply

    ga_repo.save
    ga_repo.apply

  end

  # POST /key_pairs
  # POST /key_pairs.json
  def create

    # If user uploads the public key as a file then that takes precedence over the key string
    if !key_pair_params[:file]
      # Create a .pub file on the file system
      upload_key_file(key_pair_params[:key_string], @current_user.user_name)
    else
      # Upload the file
      upload_key_file(key_pair_params[:file], @current_user.user_name)
    end

    # Save the record
    @key_pair = KeyPair.new(
      key_pair_params.merge(user_name: @current_user.user_name, user_id: @current_user.id,
                            file_name: @current_user.user_name + '.pub'))

    respond_to do |format|
      if @key_pair.save
        format.html do
          redirect_to @key_pair,
                      notice: 'Key pair was successfully created.'
        end
        format.json do
          render json: @key_pair,
                 status: :created,
                 location: @key_pair
        end
      else
        format.html { render action: "new" }
        format.json do
          render json: @key_pair.errors,
                 status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH/PUT /key_pairs/1
  # PATCH/PUT /key_pairs/1.json
  def update
    @key_pair = KeyPair.find(params[:id])

    respond_to do |format|
      if @key_pair.update_attributes(key_pair_params)
        format.html do
          redirect_to @key_pair,
                      notice: 'Key pair was successfully updated.'
        end
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json do
          render json: @key_pair.errors,
                 status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /key_pairs/1
  # DELETE /key_pairs/1.json
  def destroy
    @key_pair = KeyPair.find(params[:id])
    @key_pair.destroy

    respond_to do |format|
      format.html { redirect_to key_pairs_url }
      format.json { head :no_content }
    end
  end

  private

    # Use this method to whitelist the permissible parameters. Example:
    # params.require(:person).permit(:name, :age)
    # Also, you can specialize this method with per-user checking of
    # permissible attributes.
    def key_pair_params
      params.require(:key_pair).permit(:file, :key_string)
    end
end
