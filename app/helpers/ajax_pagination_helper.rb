require 'will_paginate'
module AjaxPaginationHelper
  # For the hash that's passed to handle_ap_event, these are the required
  # fields.
  AP_REQUIRED_KEYS = [:model, :filters]
  AP_DEFAULT_PER_PAGE = 30
  AP_DEFAULT_PAGE = 1
    
  def handle_ap_event(hash, object_hash, params)
    # First, let's make sure we have the required fields.
    # I'll take the keys from the hash, and difference it from
    # the AP_REQUIRED_FIELDS.  If there are any symbols left over
    # in the difference, the hash wasn't complete, and we should bail out.
    if (AP_REQUIRED_KEYS - hash.keys).size > 0
     # Fail loud, fail proud
      raise "handle_ap_event received an incomplete parameter hash"
    end
    # Ok, we have everything we need, let's get to work
    filter = params[:filter]
    desc = params[:desc]
    sorts = hash[:sorts]
    filters = hash[:filters]
    if(!filters.include?(filter))
      raise "Could not find filter #{filter}"
    end
    items = get_filtered_items(hash, filter, params[:sort_by], object_hash)
    if !params[:desc].blank?
      items.reverse!
    end
    if params[:per_page].blank?
      params[:per_page] = AP_DEFAULT_PER_PAGE
    end
    if params[:page].blank?
      params[:page] = AP_DEFAULT_PAGE
    end

    return items.paginate(:per_page => params[:per_page], :page => params[:page]).clone, items.size

  end
  
  def get_filters(params)
    result = {}
    params[:filters].each do |filter_key, filter|
      result[filter[:display]] = filter_key
    end
    return result
  end
  
  def get_filtered_items(hash, filter, sort_by, object_hash)
    items = hash[:filters][filter][:proc].call(object_hash)
    if !sort_by.blank?
      items = items.sort{|a,b| hash[:sorts][sort_by].call(a,b)}
    end
    return items
  end
    
end

