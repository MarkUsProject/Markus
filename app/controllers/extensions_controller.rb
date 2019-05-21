class ExtensionsController < ApplicationController
  before_action :authorize_only_for_admin

  def create_or_update
    time_delta = params[:weeks].to_i.weeks + params[:days].to_i.days + params[:hours].to_i.hours
    extension = Extension.find_or_initialize_by(grouping_id: params[:grouping_id])
    if extension.update_attributes(time_delta: time_delta, apply_penalty: params[:penalty], note: params[:note])
      flash_now(:success, I18n.t('extensions.create.success'))
    else
      flash_now(:error, I18n.t('extensions.create.error'))
    end
    head :ok
  end

  def delete_by_grouping
    if Extension.find_by_grouping_id(params[:grouping_id]).destroy
      flash_now(:success, I18n.t('extensions.delete.success'))
    else
      flash_now(:error, I18n.t('extensions.delete.error'))
    end
    head :ok
  end
end
