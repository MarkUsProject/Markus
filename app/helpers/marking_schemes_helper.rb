module MarkingSchemesHelper

def get_table_json_data
  all_marking_schemes = MarkingScheme.all

  req_data = all_marking_schemes.map do |ms|
    {
      name: ms.name,
      weights: MarkingWeight.where(marking_scheme_id: ms.id)
    }
  end

  req_data.to_json
end

end
