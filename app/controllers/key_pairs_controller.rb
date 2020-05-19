class KeyPairsController < ApplicationController
  # GET /key_pairs
  # GET /key_pairs.json
  def index
    # Grab the own user's keys only
    @key_pairs = KeyPair.where(user_id: @current_user.id)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: { key_pairs: @key_pairs } }
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

  # POST /key_pairs
  # POST /key_pairs.json
  def create
    public_key_content = ''
    # If user uploads the public key as a file then that takes precedence over
    # the key_string
    if !key_pair_params[:file]
      # Get key from key_string param
      public_key_content = key_pair_params[:key_string]
    else
      # Get key from file contents
      public_key_content = key_pair_params[:file].read
    end

    # Check to see if the public_key_content is a valid ssh key: an ssh
    # key has the format "type blob label" and cannot have a nil type or blob.
    type, blob, _label = public_key_content.split
    if !type.nil? && !blob.nil?
      # Save the record
      @key_pair = KeyPair.new(user_name: @current_user.user_name,
                              user_id:   @current_user.id,
                              public_key: public_key_content.strip)

      respond_to do |format|
        if @key_pair.save
          flash_message(:success, t('key_pairs.create.success'))
          format.html do
            redirect_to key_pairs_path
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
    else # if type and/or blob are nil
      flash_message(:error, t('key_pairs.create.invalid_key'))
      respond_to do |format|
        format.html do
          redirect_back(fallback_location: root_path)
        end
      end
    end
  end

  # DELETE /key_pairs/1
  # DELETE /key_pairs/1.json
  def destroy
    @key_pair = KeyPair.find(params[:id])

    @key_pair.destroy

    flash_message(:success, t('key_pairs.delete.success'))

    respond_to do |format|
      format.html do
        redirect_to key_pairs_path
      end
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
