# Controller responsible for managing due date extensions
class ExtensionsController < ApplicationController
  before_action { authorize! }

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
    extension = record
    if extension&.update(time_delta: duration_from_params, apply_penalty: params[:penalty], note: params[:note])
      flash_now(:success, I18n.t('extensions.create_extension'))
    else
      flash_now(:error, extension.errors.full_messages.join(' '))
    end
    head :ok
  end

  def destroy
    extension = record
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
    Extension::PARTS.sum { |part| params[part].to_i.public_send(part) }
  end

  def extension_params
    params.permit(*Extension::PARTS, :grouping_id, :penalty, :note, :id)
  end
end
