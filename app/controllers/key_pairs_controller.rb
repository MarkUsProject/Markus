class KeyPairsController < ApplicationController
  before_action { authorize! }

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
    # If user uploads the public key as a file then that takes precedence over the key_string
    public_key_content = key_pair_params[:file]&.read || key_pair_params[:key_string]
    @key_pair = KeyPair.new(user_id: @current_user.id, public_key: public_key_content.strip)
    respond_to do |format|
      if @key_pair.save
        flash_message(:success, t('key_pairs.create.success'))
        format.html { redirect_to key_pairs_path }
        format.json { render json: @key_pair, status: :created, location: @key_pair }
      else
        @key_pair.errors.full_messages.each do |message|
          flash_message(:error, message)
        end
        format.html { render action: 'new' }
        format.json { render json: @key_pair.errors, status: :unprocessable_entity }
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
