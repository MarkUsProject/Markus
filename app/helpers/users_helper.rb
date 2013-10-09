module UsersHelper

  # Construct table rows for multiple users
  def construct_table_rows(users)
    result = {}
    users.each do |user|
      result[user.id] = construct_table_row(user)
    end
    result
  end

  # Construct a single table row
  def construct_table_row(user)
    result = {}
    result[:id] = user.id
    result[:user_name] = CGI.escapeHTML(user.user_name)
    result[:first_name] = CGI.escapeHTML(user.first_name)
    result[:last_name] = CGI.escapeHTML(user.last_name)
    @render_note_link = false
    if user.student?
      result[:grace_credits] = user.remaining_grace_credits.to_s + '/' + user.grace_credits.to_s
      if user.has_section?
        result[:section] = user.section.name
      else
        result[:section] = '-'
      end
      @render_note_link = true
    end
    result[:hidden] = user.hidden
    result[:filter_table_row_contents] =
       render_to_string :partial => 'users/table_row/filter_table_row.html.erb',
                        :locals => {:user => user,
                                    :controller => self.controller_name,
                                    :render_note_link => @render_note_link}
    result
  end

  # Construct a nicely formatted JSON response in the form of an array for our student table
  def construct_students_table_data(users)
    student_list = []
    users.each do |user|
      result = []
      result[0] = CGI.escapeHTML(user.user_name)
      result[1] = CGI.escapeHTML(user.last_name)
      result[2] = CGI.escapeHTML(user.first_name)
      student_list.push(result)
      @render_note_link = false
      if user.student?
        result[3] = user.remaining_grace_credits.to_s + '/' + user.grace_credits.to_s
        if user.has_section?
          result[4] = user.section.name
        else
          result[4] = '-'
        end
        @render_note_link = true
      end
      result[5] = user.hidden
      result[6] = "<%= link_to I18n.t(:edit), :controller => 'students', :action =>'edit', :id => #{user.id} %>"
    end
    return student_list
  end

end
