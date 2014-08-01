module AdminsHelper
  def get_admins_table_info
    admins = Admin.all
    admins.map do |admin|
      a = admin.attributes
      a['edit_link'] = url_for(controller: 'admins',
                               action: 'edit',
                               id: admin.id)
      a
    end
  end
end
