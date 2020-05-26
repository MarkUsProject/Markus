module MarkingSchemesHelper
  def get_table_json_data
    all_marking_schemes = MarkingScheme.all
    assignment_weights = MarkingWeight.joins(:assessments).where(marking_scheme_id: ms.id, type: 'Assignment')
    grade_entry_form_weights = MarkingWeight.joins(:assessments).where(marking_scheme_id: ms.id, type: 'GradeEntryForm')

    req_data = all_marking_schemes.map do |ms|
      {
        name: ms.name,
        id: ms.id,
        assignment_weights: get_marking_weights_for_all_gradable_item(assignment_weights),
        grade_entry_form_weights: get_marking_weights_for_all_gradable_item(grade_entry_form_weights),
        edit_link: get_edit_link_for_marking_scheme_id(ms.id),
        delete_link: get_delete_link_for_marking_scheme_id(ms.id)
      }
    end

    req_data
  end

  def get_edit_link_for_marking_scheme_id(id)
    url_for(
      controller: 'marking_schemes',
      action: 'edit',
      id: id)
  end

  def get_delete_link_for_marking_scheme_id(id)
    url_for(
      controller: 'marking_schemes',
      action: 'destroy',
      id: id)
  end

  def get_marking_weights_for_all_gradable_item(weights_array)
    weights = {}
    weights_array.all.each do |w|
      weights[w.assessment_id] = w.weight.to_f
    end
    weights
  end
end
