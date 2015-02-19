module MarkingSchemesHelper

def get_table_json_data
  all_marking_schemes = MarkingScheme.all
  all_marking_schemes.to_json
end

end
