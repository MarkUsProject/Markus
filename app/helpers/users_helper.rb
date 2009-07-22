module UsersHelper

  # Construct table rows for multiple users
  def construct_table_rows(users)
    result = {}
    users.each do |user|
      result[user.id] = construct_table_row(user)
    end
    return result
  end
  
  # Construct a single table row
  def construct_table_row(user) 
    result = {}
    result[:id] = user.id
    result[:user_name] = CGI.escapeHTML(user.user_name)
    result[:first_name] = CGI.escapeHTML(user.first_name)
    result[:last_name] = CGI.escapeHTML(user.last_name)
    result[:hidden] = user.hidden
    result[:edit] = render_to_string :partial => "users/table_row/edit", :locals => {:user => user, :controller => self.controller_name}
    return result
  end

end
