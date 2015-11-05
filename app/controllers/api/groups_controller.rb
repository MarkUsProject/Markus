module Api

  # Allows for listing Markus groups for a particular assignment.
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class GroupsController < MainApiController
    # Define default fields to display for index and show methods
    @@default_fields = [:id, :group_name, :created_at, :updated_at, :first_name,
                        :last_name, :user_name, :membership_status,
                        :student_memberships]

    # Returns an assignment's groups along with their attributes
    # Requires: assignment_id
    # Optional: filter, fields
    def index
      assignment = Assignment.find_by_id(params[:assignment_id])
      if assignment.nil?
        # No assignment with that id
        render 'shared/http_status', locals: {code: '404', message:
          'No assignment exists with that id'}, status: 404
        return
      end

      collection = Group.joins(:assignments).where(assignments:
        {id: params[:assignment_id]})
      groups = get_collection(Group, collection)
      fields = fields_to_render(@@default_fields)

      students = include_students(fields)

      respond_to do |format|
        format.xml{render xml: groups.to_xml(only: fields, root:
          'groups', skip_types: 'true', include: students)}
        format.json{render json: groups.to_json(only: fields,
          include: students)}
      end
    end

    # Returns a single group along with its attributes
    # Requires: assignment_id, id
    # Optional: fields
    def show
      # Error if no assignment exists with that id
      assignment = Assignment.find_by_id(params[:assignment_id])
      if assignment.nil?
        render 'shared/http_status', locals: {code: '404', message:
          'No assignment exists with that id'}, status: 404
        return
      end

      # Error if no group exists with that id
      group = Group.find_by_id(params[:id])
      if group.nil?
        render 'shared/http_status', locals: {code: '404', message:
          'No group exists with that id'}, status: 404
        return
      end

      if group.grouping_for_assignment(params[:assignment_id])
        # We found a grouping for that assignment
        fields = fields_to_render(@@default_fields)
        students = include_students(fields)

        respond_to do |format|
          format.xml{render xml: group.to_xml(only: fields, root:
            'group', skip_types: 'true', include: students)}
          format.json{render json: group.to_json(only: fields,
            include: students)}
        end
      else
        # The group doesn't have a grouping associated with that assignment
        render 'shared/http_status', locals: {code: '422', message:
          'The group is not involved with that assignment'}, status: 422
      end
    end

    # Include student_memberships and user info if required
    def include_students(fields)
      if fields.include?(:student_memberships)
        {student_memberships: {include: :user}}
      end
    end

    # Update the group's marks for the given assignment.
    def update_marks
      assignment = Assignment.find(params[:assignment_id])
      if assignment.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'No assignment exists with that id' }, status: 404
        return
      end

      group = Group.find(params[:id])
      if group.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'No group exists with that id' }, status: 404
        return
      end
      if group.grouping_for_assignment(params[:assignment_id])
              .has_submission?
        result = group.grouping_for_assignment(params[:assignment_id])
                      .current_submission_used
                      .get_latest_result
      else
        render 'shared/http_status', locals: { code: '404', message:
          'No submissions exist for that group' }, status: 404
        return
      end

      # We shouldn't be able to update marks if marking is already complete.
      if result.marking_state == Result::MARKING_STATES[:complete]
        render 'shared/http_status', locals: { code: '404', message:
          'Marking for that submission is already completed' }, status: 404
        return
      end

      matched_criteria = RubricCriterion
                           .where(rubric_criterion_name: params.keys,
                                  assignment_id: params[:assignment_id])
      matched_criteria.concat(FlexibleCriterion
                                .where(flexible_criterion_name: params.keys,
                                       assignment_id: params[:assignment_id]))
      if matched_criteria.empty?
        render 'shared/http_status', locals: { code: '404', message:
          'No criteria were found that match that request.' }, status: 404
        return
      end

      matched_criteria.each do |crit|
        mark_to_change = result.marks.find_or_create_by(
          markable_id: crit.id,
          markable_type: crit.class.name)
        unless set_mark_by_criteria(crit, mark_to_change)
          # Some error occurred (including invalid mark)
          render 'shared/http_status', locals: { code: '500', message:
            mark_to_change.errors.full_messages.first }, status: 500
          return
        end
      end
      render 'shared/http_status', locals: { code: '200', message:
        HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
    end

    def set_mark_by_criteria(criteria, mark_to_change)
      if criteria.is_a?(FlexibleCriterion)
        if params[criteria.flexible_criterion_name] == 'nil'
          mark_to_change.mark = nil
        else
          mark_to_change.mark = params[criteria.flexible_criterion_name].to_f
        end
      else
        if params[criteria.rubric_criterion_name] == 'nil'
          mark_to_change.mark = nil
        else
          mark_to_change.mark = params[criteria.rubric_criterion_name]
        end
      end
      mark_to_change.save
    end

    # Return key:value pairs of group_name:group_id
    def group_ids_by_name
      groups = Assignment.find(params[:assignment_id])
                        .groups
      reversed = Hash[groups.map { |g| [g.group_name, g.id] }]
      respond_to do |format|
        format.xml do
          render xml: reversed.to_xml(root: 'groups', skip_types: 'true')
        end
        format.json do
          render json: reversed.to_json
        end
      end
    end

    # Allow user to set marking state to complete
    def update_marking_state
      group = Group.find(params[:id])
      result = group.grouping_for_assignment(params[:assignment_id])
                    .current_submission_used
                    .get_latest_result
      result.marking_state = params[:marking_state]
      if result.save
        result.submission.assignment.assignment_stat.refresh_grade_distribution
        result.submission.assignment.update_results_stats
        render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
      else
        render 'shared/http_status', locals: { code: '500', message:
          result.errors.full_messages.first }, status: 500
      end
    end
  end # end GroupsController
end
