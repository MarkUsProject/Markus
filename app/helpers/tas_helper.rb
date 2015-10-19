module TasHelper
  def get_tas_table_info
    tas = Ta.all
    @tas_table_info = tas.map do |ta|
      t = ta.attributes
      t['edit_link'] = url_for(controller: 'tas',
                               action: 'edit',
                               id: ta.id)
      t['delete_link'] = url_for(controller: 'tas',
                                 action: 'destroy',
                                 id: ta.id)
      t
    end
  end
end
