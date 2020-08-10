class KeyPairsController < ApplicationController
  before_action { authorize! }

  # GET /key_pairs
  def index
    # Grab the own user's keys only
    @key_pairs = @current_user.key_pairs
  end

  # GET /key_pairs/new
  def new
    @key_pair = @current_user.key_pairs.new
  end

  # POST /key_pairs
  def create
    # If user uploads the public key as a file then that takes precedence over the key_string
    public_key_content = key_pair_params[:file]&.read || key_pair_params[:key_string]
    @key_pair = @current_user.key_pairs.new(public_key: public_key_content.strip)
    if @key_pair.save
      flash_message(:success, t('key_pairs.create.success'))
      redirect_to key_pairs_path
    else
      @key_pair.errors.full_messages.each do |message|
        flash_message(:error, message)
      end
      render action: 'new'
    end
  end

  # DELETE /key_pairs/1
  def destroy
    # only allowed to destroy your own key_pairs
    @key_pair = @current_user.key_pairs.find_by(id: params[:id])

    flash_message(:success, t('key_pairs.delete.success')) if @key_pair&.destroy
    redirect_to key_pairs_path
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
