# Controller responsible for managing due date extensions
class ExtensionsController < ApplicationController
  before_action :authorize_only_for_admin

  # Create a new extension object for the grouping with id=+params[:grouping_id]+ or
  # update the existing extension object for that grouping.
  def create_or_update
    params = extension_params
    extension = Extension.find_or_initialize_by(grouping_id: params[:grouping_id])
    if extension.update_attributes(grouping_id: params[:grouping_id],
                                   time_delta: duration_from_params,
                                   apply_penalty: params[:penalty],
                                   note: params[:note])
      flash_now(:success, I18n.t('extensions.create.success'))
    else
      flash_now(:error, I18n.t('extensions.create.error'))
    end
    head :ok
  end

  # Delete an extension object for the grouping with id=+params[:grouping_id]+
  def delete_by_grouping
    params = extension_params
    if Extension.find_by_grouping_id(params[:grouping_id])&.destroy
      flash_now(:success, I18n.t('extensions.delete.success'))
    else
      flash_now(:error, I18n.t('extensions.delete.error'))
    end
    head :ok
  end

  private

  def duration_from_params
    params = extension_params
    Extension::PARTS.map { |part| params[part].to_i.send(part) }.sum
  end

  def extension_params
    params.permit(*Extension::PARTS, :grouping_id, :penalty, :note)
  end
end
