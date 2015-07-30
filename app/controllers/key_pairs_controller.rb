class KeyPairsController < ApplicationController
  # GET /key_pairs
  # GET /key_pairs.json
  def index
    # Grab the own user's keys only
    @key_pairs = KeyPair.where(user_id: @current_user.id)

    @key_strings = Array.new

    @key_pairs.each do |keypair|
      # Read the key
      key = File.open(File.join(KEY_STORAGE, keypair.file_name))
      @key_strings.pushkey.read)
    end

    @key_pairs = @key_pairs.zip(@key_strings)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: { key_pairs: @key_pairs } }
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
  def upload_key_file(file_content, time_stamp)
    create_key_directory

    write_key(file_content, time_stamp)

    add_key(File.join(KEY_STORAGE, @current_user.user_name +
                                   "@#{time_stamp}.pub"))
  end

  def write_key(file_content, time_stamp)
    File.open(Rails.root.join(KEY_STORAGE, @current_user.user_name + '@' +
                                             time_stamp + '.pub'), 'wb') do |f|
      f.write(file_content)
    end
  end

  # Creates the KEY_STORAGE directory if required
  def create_key_directory
    Dir.mkdir(KEY_STORAGE) unless File.exists?(KEY_STORAGE)
  end

  # Adds a specific public key to a specific user.
  def add_key(_path)
    ga_repo = Gitolite::GitoliteAdmin.new(
      File.join(REPOSITORY_STORAGE, 'gitolite-admin'), GITOLITE_SETTINGS)

    # Check to see if an individual repo exists for this user
    key = Gitolite::SSHKey.from_file(_path)

    ga_repo.add_key(key)

    admin_key = Gitolite::SSHKey.from_file(GITOLITE_SETTINGS[:public_key])
    ga_repo.add_key(admin_key)

    # update Gitolite repo
    ga_repo.save_and_apply
  end

  # Deletes a specific public key from a specific user.
  def remove_key(_path)
    ga_repo = Gitolite::GitoliteAdmin.new(
      REPOSITORY_STORAGE + '/gitolite-admin', GITOLITE_SETTINGS)

    # Check to see if an individual repo exists for this user
    key = Gitolite::SSHKey.from_file(_path)

    ga_repo.rm_key(key)

    admin_key = Gitolite::SSHKey.from_file(GITOLITE_SETTINGS[:public_key])
    ga_repo.add_key(admin_key)

    # update Gitolite repo
    ga_repo.save_and_apply
  end

  # POST /key_pairs
  # POST /key_pairs.json
  def create
    # Used to uniquely identify key
    time_stamp = Time.now.to_i.to_s

    public_key_content = ''

    if !key_pair_params[:file]
      # Dump the string into the file
      public_key_content = key_pair_params[:key_string]
    else
      public_key_content = key_pair_params[:file].read
    end

    # If user uploads the public key as a file then that takes precedence over
    # the key string
    if !key_pair_params[:file]
      # Create a .pub file on the file system
      upload_key_file(public_key_content, time_stamp)
    else
      # Upload the file
      upload_key_file(public_key_content, time_stamp)
    end

    # Save the record
    @key_pair = KeyPair.new(
      key_pair_params.merge(user_name: @current_user.user_name,
                            user_id: @current_user.id,
                            file_name: @current_user.user_name +
                                '@' + time_stamp + '.pub'))

    respond_to do |format|
      if @key_pair.save
        format.html do
          redirect_to key_pairs_path,
                      notice: 'Key pair was successfully created.'
        end
        format.json do
          render json: @key_pair,
                 status: :created,
                 location: @key_pair
        end
      else
        format.html { render action: 'new' }
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
        format.html { render action: 'edit' }
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

    remove_key(File.join(KEY_STORAGE, @key_pair.file_name))

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
