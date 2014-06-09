class SummariesController < ApplicationController
  include PaginationHelper

  def index
    if params[:filter].blank?
      params[:filter] = 'none'
    end

    @assignment = Assignment.find(params[:assignment_id])

    @c_per_page = current_user.id.to_s + '_' + @assignment.id.to_s + '_per_page'
    if params[:per_page].present?
      cookies[@c_per_page] = params[:per_page]
    elsif cookies[@c_per_page].present?
      params[:per_page] = cookies[@c_per_page]
    end

    @c_sort_by = current_user.id.to_s + '_' + @assignment.id.to_s + '_sort_by'
    @c_cid = current_user.id.to_s + '_' + @assignment.id.to_s + '_cid'
    if params[:sort_by].present?
      cookies[@c_sort_by] = params[:sort_by]
      if params[:sort_by] == 'criterion'
        # we are sorting by one of the marking criteria
        cookies[@c_cid] = params[:cid]
      end
    elsif cookies[@c_sort_by].present?
      params[:sort_by] = cookies[@c_sort_by]
      if cookies[@c_sort_by] == 'criterion'
        params[:cid] = cookies[@c_cid]
      end
    else
      params[:sort_by] = 'group_name'
    end

    # the data structure to handle filtering and sorting
    # the assignment to filter by
    # the submissions accessible by the current user
    # additional parameters that affect things like sorting
    if current_user.ta?
      @groupings, @groupings_total = handle_paginate_event(
                                       SubmissionsController::TA_TABLE_PARAMS,
                                       { assignment: @assignment,
                                         user_id: current_user.id },
                                       params)
    else
      object_hash = { assignment: @assignment,
                      user_id: current_user.id }
      if params[:sort_by] == 'criterion'
        # pass the criterion id on to handle_paginate_event
        object_hash[:cid] = params[:cid]
      end

      @groupings, @groupings_total = handle_paginate_event(
        SubmissionsController::ADMIN_TABLE_PARAMS,
        object_hash,
        params)
    end

    # Eager load all data only for those groupings that will be displayed
    sorted_groupings = @groupings
    @groupings = Grouping.all(conditions: { id: sorted_groupings },
                              include: [:assignment,
                                        :group,
                                        :grace_period_deductions,
                                        { current_submission_used: :results },
                                        { accepted_student_memberships: :user }
                                       ]
                             )

    # re-sort @groupings by the previous order, because eager loading query
    # messed up the grouping order
    @groupings = sorted_groupings.map do |sorted_grouping|
      @groupings.detect do |unsorted_grouping|
        unsorted_grouping == sorted_grouping
      end
    end

    if cookies[@c_per_page].blank?
      cookies[@c_per_page] = params[:per_page]
    end

    if cookies[@c_sort_by].blank?
      cookies[@c_sort_by] = params[:sort_by]
      if params[:sort_by] == 'criterion'
        cookies[@c_cid] = params[:cid]
      end
    end

    @current_page = params[:page].to_i
    @per_page = cookies[@c_per_page]

    if current_user.ta?
      @filters = get_filters(SubmissionsController::TA_TABLE_PARAMS)
      @per_pages = SubmissionsController::TA_TABLE_PARAMS[:per_pages]
    else
      @filters = get_filters(SubmissionsController::ADMIN_TABLE_PARAMS)
      @per_pages = SubmissionsController::ADMIN_TABLE_PARAMS[:per_pages]
    end

    @desc = params[:desc]
    @filter = params[:filter]
    @sort_by = cookies[@c_sort_by]
    if @sort_by == 'criterion'
      @cid = cookies[@c_cid]
    end
  end
end
