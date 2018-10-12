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
      assignment = Assignment.find_by(id: params[:assignment_id])
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
      assignment = Assignment.find_by(id: params[:assignment_id])
      if assignment.nil?
        render 'shared/http_status', locals: {code: '404', message:
          'No assignment exists with that id'}, status: 404
        return
      end

      # Error if no group exists with that id
      group = Group.find_by(id: params[:id])
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
      matched_criteria = assignment.get_criteria.select{ |criterion| params.keys.include?(criterion.name) }
      if matched_criteria.empty?
        render 'shared/http_status', locals: { code: '404', message:
          'No criteria were found that match that request.' }, status: 404
        return
      end

      matched_criteria.each do |crit|
        mark_to_change = result.marks.find_or_initialize_by(markable_id: crit.id, markable_type: crit.class.name)
        mark_to_change.mark = params[crit.name] == 'nil' ? nil : params[crit.name].to_f
        unless mark_to_change.save
          # Some error occurred (including invalid mark)
          render 'shared/http_status', locals: { code: '500', message:
            mark_to_change.errors.full_messages.first }, status: 500
          return
        end
      end
      result.reload
      result.update_total_mark
      result.save
      render 'shared/http_status', locals: { code: '200', message:
        HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
    end

    def add_annotations
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
                      .current_result
      else
        render 'shared/http_status', locals: { code: '404', message:
          'No submissions exist for that group' }, status: 404
        return
      end

      force_complete = params.fetch(:force_complete, false)
      # We shouldn't be able to update annotations if marking is already complete, unless forced.
      if result.marking_state == Result::MARKING_STATES[:complete] && !force_complete
        render 'shared/http_status', locals: { code: '404', message:
          'Marking for that submission is already completed' }, status: 404
        return
      end

      annotation_texts = []
      annotations = []
      count = result.submission.annotations.count + 1
      annotation_category = nil
      submission_file = nil
      params[:annotations].each_with_index do |annot_params, i|
        if annot_params[:annotation_category_name].nil?
          annotation_category_id = nil
        else
          if annotation_category.nil? || annotation_category.annotation_category_name != annot_params[:annotation_category_name]
            annotation_category = assignment.annotation_categories.find_or_create_by(
              annotation_category_name: annot_params[:annotation_category_name]
            )
          end
          annotation_category_id = annotation_category.id
        end
        if submission_file.nil? || submission_file.filename != annot_params[:filename]
          submission_file = result.submission.submission_files.find_by(filename: annot_params[:filename])
        end

        annotation_texts << AnnotationText.new(
          content: annot_params[:content],
          annotation_category_id: annotation_category_id,
          creator_id: @current_user.id,
          last_editor_id: @current_user.id
        )
        annotations << TextAnnotation.new(
          line_start: annot_params[:line_start],
          line_end: annot_params[:line_end],
          column_start: annot_params[:column_start],
          column_end: annot_params[:column_end],
          annotation_text_id: nil,
          submission_file_id: submission_file.id,
          creator_id: @current_user.id,
          creator_type: @current_user.type,
          is_remark: !result.remark_request_submitted_at.nil?,
          annotation_number: count + i,
          result_id: result.id
        )
      end
      AnnotationText.import annotation_texts, validate: false
      annotation_texts.zip(annotations) do |t, a|
        a.annotation_text_id = t.id
      end
      TextAnnotation.import annotations, validate: false
      render 'shared/http_status', locals: { code: '200', message:
        HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
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
      if has_missing_params?([:marking_state])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: {code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422']}, status: 422
        return
      end
      group = Group.find(params[:id])
      if group.grouping_for_assignment(params[:assignment_id])
             .has_submission?
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
      else
        render 'shared/http_status', locals: { code: '404', message:
            'No submissions exist for that group' }, status: 404
        return
      end
    end

    private

    def annotations_params
      params.require(annotations: [
        :annotation_category_name,
        :column_end,
        :column_start,
        :content,
        :filename,
        :line_end,
        :line_start
      ])
    end
  end # end GroupsController
end
