module AssignmentsHelper

  def add_assignment_file_link(name, form)
    link_to_function name do |page|
      assignment_file = render(:partial => 'assignment_file', :locals => {:form => form, :assignment_file => AssignmentFile.new})
      page << %{
        var new_assignment_file_id = "new_" + new Date().getTime();
        $('assignment_files').insert({bottom: "#{ escape_javascript assignment_file }".replace(/(attributes_\\d+|\[\\d+\])/g, new_assignment_file_id) });
      }
    end
  end

  def add_grace_period_link(name, form)
    link_to_function name do |page|
      period = render(:partial => 'grace_period', :locals => {:pf => form, :grace_period => Period.new})
      page << %{
        if ($F('grace_period_submission_rule') != null) {
          var new_period_id = "new_" + new Date().getTime();
          $('grace_periods').insert({bottom: "#{ escape_javascript period }".replace(/(attributes_\\d+|\[\\d+\])/g, new_period_id) });
        } else {
          alert("#{I18n.t("submission_rules.grace_period_submission_rule.alert")}");
        }
      }
    end
  end
  
  def add_penalty_period_link(name, form)
    link_to_function name do |page|
      period = render(:partial => 'penalty_period', :locals => {:pf => form, :penalty_period => Period.new})
      page << %{
      if ($F('penalty_period_submission_rule') != null) {
        var new_period_id = "new_" + new Date().getTime();
        $('penalty_periods').insert({bottom: "#{ escape_javascript period }".replace(/(attributes_\\d+|\[\\d+\])/g, new_period_id) });
      }  else {
          alert("#{I18n.t("submission_rules.penalty_period_submission_rule.alert")}");
        }
     }
    end
  end
  
end
