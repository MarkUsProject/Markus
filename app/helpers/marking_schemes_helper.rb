module MarkingSchemesHelper
  def get_table_json_data
    all_marking_schemes = MarkingScheme.all

    req_data = all_marking_schemes.map do |ms|
      {
        name: ms.name,
        id: ms.id,
        assignment_weights: get_marking_weights_for_all_gradable_item(
          MarkingWeight.where(marking_scheme_id: ms.id, is_assignment: true)),
        spreadsheet_weights: get_marking_weights_for_all_gradable_item(
          MarkingWeight.where(marking_scheme_id: ms.id, is_assignment: false)),
        edit_link: get_edit_link_for_marking_scheme_id(ms.id),
        delete_link: get_delete_link_for_marking_scheme_id(ms.id)
      }
    end

    req_data.to_json
  end

  def get_edit_link_for_marking_scheme_id(id)
    url_for(
      controller: 'marking_schemes',
      action: 'edit',
      id: id)
    # view_context.link_to(
    #   'Edit',
    #   edit_marking_scheme_path(id),
    #   remote: true)
  end

  def get_delete_link_for_marking_scheme_id(id)
    url_for(
      controller: 'marking_schemes',
      action: 'destroy',
      id: id)
    # view_context.link_to(
    #   'Delete',
    #   controller: 'marking_schemes',
    #   action: 'destroy',
    #   data: { confirm: 'Are you sure you want to delete this tag?' },
    #   remote
    #   id: id)
  end

  def get_marking_weights_for_all_gradable_item(weights_array)
    weights = {}
    weights_array.all.each do |w|
      weights[w.gradable_item_id] = w.weight
    end
    weights
  end
end
