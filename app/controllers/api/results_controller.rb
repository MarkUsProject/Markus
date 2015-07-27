module Api
  # Allows for updating submission results.
  # Requires that the submission be collected.
  class ResultsController < MainApiController

    # Update a result.
    def update
      assignment = Assignment.find_by_id(params[:assignment_id])
      if assignment.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'No assignment exists with that id' }, status: 404
        return
      end

      group = Group.find_by_id(params[:group_id])
      if group.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'No group exists with that id' }, status: 404
        return
      elsif group.submissions.first.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'No submissions exist for that group' }, status: 404
        return
      end

      all_criteria = assignment.rubric_criteria
      all_criteria.push(*assignment.flexible_criteria)
      if all_criteria.empty?
        render 'shared/http_status', locals: { code: '404', message:
          'No criteria exist for that assignment' }, status: 404
        return
      end

      result = group.submissions.first.get_latest_result

      params.keys.each do |param_key|
        all_criteria.each do |criteria|
          if (criteria.rubric_criterion_name ==  param_key)
            mark_to_change = result.marks
                                   .where(markable_id: criteria.id)
                                   .first
            mark_to_change.mark = params[param_key].to_i
            unless mark_to_change.save
              # Some error occurred (including invalid mark)
              render 'shared/http_status', locals: { code: '500', message:
                HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
              return
            end
          end
        end
      end

      # Otherwise everything went alright.
      render 'shared/http_status', locals: { code: '200', message:
        HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
    end
  end
end
