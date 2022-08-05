module MarkingSchemesHelper
  def get_table_json_data(course)
    course.marking_schemes.map do |ms|
      {
        name: ms.name,
        id: ms.id,
        assessment_weights: get_marking_weights_for_all_gradable_item(MarkingWeight.where(marking_scheme_id: ms.id)),
        edit_link: get_edit_link_for_marking_scheme_id(ms.id),
        delete_link: get_delete_link_for_marking_scheme_id(ms.id)
      }
    end
  end

  def get_edit_link_for_marking_scheme_id(id)
    url_for(
      controller: 'marking_schemes',
      action: 'edit',
      id: id
    )
  end

  def get_delete_link_for_marking_scheme_id(id)
    url_for(
      controller: 'marking_schemes',
      action: 'destroy',
      id: id
    )
  end

  def get_marking_weights_for_all_gradable_item(weights_array)
    weights = {}
    weights_array.each do |w|
      weights[w.assessment_id] = w.weight.to_f
    end
    weights
  end
end
