module MarkingSchemesHelper

def get_table_json_data
  all_marking_schemes = MarkingScheme.all

  req_data = {}

  # MarkingScheme.all.each do |ms|
  #   req_data[ms.id] = {
  #     assignment_weights: get_marking_weights_for_all_gradable_item(MarkingWeight.where(marking_scheme_id: ms.id, is_assignment: true)),
  #     spreadsheet_weights: get_marking_weights_for_all_gradable_item(MarkingWeight.where(marking_scheme_id: ms.id, is_assignment: false))
  #   }
  # end

  req_data = all_marking_schemes.map do |ms|
    {
      name: ms.name,
      id: ms.id,
      assignment_weights: get_marking_weights_for_all_gradable_item(MarkingWeight.where(marking_scheme_id: ms.id, is_assignment: true)),
      spreadsheet_weights: get_marking_weights_for_all_gradable_item(MarkingWeight.where(marking_scheme_id: ms.id, is_assignment: false))
    }
  end

  req_data.to_json
end

def get_marking_weights_for_all_gradable_item(weights_array)
  weights = {}
  weights_array.all.each do |w|
    weights[w.gradable_item_id] = w.weight
  end
  weights
end

end
