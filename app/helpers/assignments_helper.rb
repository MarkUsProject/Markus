module AssignmentsHelper

  def add_assignment_file_link(name, form)
    link_to_function name do |page|
      assignment_file = render(:partial => 'assignment_file', :locals => {:form => form, :assignment_file => AssignmentFile.new})
      page << %{
        var new_assignment_file_id = "new_" + new Date().getTime();
        $('assignment_files').insert({bottom: "#{ escape_javascript assignment_file }".replace(/(attributes_\\d+|\[\\d+\])/g, new_assignment_file_id) });
        $('assignment_assignment_files_' + new_assignment_file_id + '_filename').focus();
      }
    end
  end

  def add_grace_period_link(name, form, element_id)
    link_to_function name , nil, :id => element_id, :style => 'display:none' do |page|
      period = render(:partial => 'grace_period', :locals => {:pf => form, :grace_period => Period.new})
      page << %{
        if ($F('grace_period_submission_rule') != null) {
          var new_period_id = new Date().getTime();
          $('grace_periods').insert({bottom: "#{ escape_javascript period }".replace(/(attributes_\\d+|\[\\d+\])/g, new_period_id) });
          $('assignment_submission_rule_attributes_periods_' + new_period_id + '_hours').focus();
        } else {
          alert("#{I18n.t('submission_rules.grace_period_submission_rule.alert')}");
        }
      }
    end
  end

  def add_penalty_decay_period_link(name, form, element_id)
    link_to_function name , nil, :id => element_id, :style => 'display:none' do |page|
      period = render(:partial => 'penalty_decay_period', :locals => {:pf => form, :penalty_decay_period => Period.new})
      page << %{
      if ($F('penalty_decay_period_submission_rule') != null) {
        var new_period_id =  new Date().getTime();
        $('penalty_decay_periods').insert({bottom: "#{ escape_javascript period }".replace(/(attributes_\\d+|\[\\d+\])/g, new_period_id) });
        $('assignment_submission_rule_attributes_periods_' + new_period_id + '_hours').focus();
      }  else {
          alert("#{I18n.t('submission_rules.penalty_decay_period_submission_rule.alert')}");
        }
     }
    end
  end

  def add_penalty_period_link(name, form, element_id)
    link_to_function name , nil, :id => element_id, :style => 'display:none' do |page|
      period = render(:partial => 'penalty_period', :locals => {:pf => form, :penalty_period => Period.new})
      page << %{
      if ($F('penalty_period_submission_rule') != null) {
        var new_period_id =  new Date().getTime();
        $('penalty_periods').insert({bottom: "#{ escape_javascript period }".replace(/(attributes_\\d+|\[\\d+\])/g, new_period_id) });
        $('assignment_submission_rule_attributes_periods_' + new_period_id + '_hours').focus();
      }  else {
          alert("#{I18n.t('submission_rules.penalty_period_submission_rule.alert')}");
        }
     }
    end
  end

end
