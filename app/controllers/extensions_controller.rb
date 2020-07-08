# Controller responsible for managing due date extensions
class ExtensionsController < ApplicationController
  before_action :authorize_only_for_admin

  def create
    params = extension_params
    extension = Extension.new(grouping_id: params[:grouping_id],
                              time_delta: duration_from_params,
                              apply_penalty: params[:penalty],
                              note: params[:note])
    if extension.save
      flash_now(:success, I18n.t('extensions.create_extension'))
    else
      flash_now(:error, extension.errors.full_messages.join(' '))
    end
    head :ok
  end

  def update
    params = extension_params
    extension = Extension.find(params[:id])
    if extension&.update(grouping_id: params[:grouping_id],
                                    time_delta: duration_from_params,
                                    apply_penalty: params[:penalty],
                                    note: params[:note])
      flash_now(:success, I18n.t('extensions.create_extension'))
    else
      flash_now(:error, extension.errors.full_messages.join(' '))
    end
    head :ok
  end

  def destroy
    extension = Extension.find(params[:id])
    if extension&.destroy&.destroyed?
      flash_now(:success, I18n.t('extensions.delete_extension'))
    else
      flash_now(:error, extension.errors.full_messages.join(' '))
    end
    head :ok
  end

  private

  def duration_from_params
    params = extension_params
    Extension::PARTS.map { |part| params[part].to_i.send(part) }.sum
  end

  def extension_params
    params.permit(*Extension::PARTS, :grouping_id, :penalty, :note, :id)
  end
end
