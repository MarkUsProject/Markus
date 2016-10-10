module TasHelper
  def get_tas_table_info
    tas = Ta.all
    @tas_table_info = tas.map do |ta|
      t = ta.attributes
      t['edit_link'] = edit_ta_path(ta.id)
      t['delete_link'] = ta_path(ta.id)
      t
    end
  end
end
