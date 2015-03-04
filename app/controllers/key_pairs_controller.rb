class KeyPairsController < ApplicationController
  # GET /key_pairs
  # GET /key_pairs.json
  def index
    @key_pairs = KeyPair.all

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
  # Admins are able to save keys under different user names then
  # their own.
  # Creates the KEY_STORAGE directory if it does not yet exist
  def upload_key_file(_file, user_name)
    Dir.mkdir(KEY_STORAGE) unless File.exists?(KEY_STORAGE)
    uploaded_io = _file

    # todo: check current user to see if they have permission to
    # use a different user_name then their current one (admins)

    File.open(Rails.root.join(KEY_STORAGE, user_name + '.pub'), 'wb') do |f|
      f.write(uploaded_io.read)
    end

  end

  # POST /key_pairs
  # POST /key_pairs.json
  def create

    # Upload the file
    upload_key_file(key_pair_params[:file], @current_user.user_name)

    # Save the record
    @key_pair = KeyPair.new(
        key_pair_params.merge(:user_name => @current_user.user_name,
                              :file_name => @current_user.user_name + '.pub'))

    respond_to do |format|
      if @key_pair.save
        format.html do redirect_to @key_pair,
                      notice: 'Key pair was successfully created.'
        end
        format.json do render json: @key_pair,
                             status: :created,
                             location: @key_pair
        end
      else
        format.html { render action: "new" }
        format.json do render json: @key_pair.errors,
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
        format.html do redirect_to @key_pair,
                                   notice: 'Key pair was successfully updated.'
        end
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json do render json: @key_pair.errors,
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
      params.require(:key_pair).permit(:file)
    end
end
