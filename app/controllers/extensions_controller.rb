class ExtensionsController < ApplicationController
  before_action :authorize_only_for_admin

  def create_or_update
    time_delta = params[:weeks].to_i.weeks + params[:days].to_i.days + params[:hours].to_i.hours
    Extension.find_or_initialize_by(grouping_id: params[:grouping_id])
             .update_attributes(time_delta: time_delta,
                                apply_penalty: params[:penalty],
                                note: params[:note])
    head :ok
  end

  def delete_by_grouping
    Extension.find_by_grouping_id(params[:grouping_id]).destroy
    head :ok
  end
end
