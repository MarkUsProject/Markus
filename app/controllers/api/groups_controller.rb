module Api

  # Allows for listing Markus groups for a particular assignment.
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class GroupsController < MainApiController
    # Define default fields to display for index and show methods
    DEFAULT_FIELDS = [:id, :group_name].freeze

    # Returns an assignment's groups along with their attributes
    # Requires: assignment_id
    # Optional: filter, fields
    def index
      groups = get_collection(assignment.groups) || return

      group_data = include_memberships(groups)

      respond_to do |format|
        format.xml do
          render xml: group_data.to_xml(root: 'groups', skip_types: 'true')
        end
        format.json { render json: group_data }
      end
    end

    # Returns a single group along with its attributes
    # Requires: id
    # Optional: fields
    def show
      group_data = include_memberships(Group.where(id: record.id))

      # We found a grouping for that assignment
      respond_to do |format|
        format.xml do
          render xml: group_data.to_xml(root: 'groups', skip_types: 'true')
        end
        format.json { render json: group_data }
      end
    end

    # Include student_memberships and user info
    def include_memberships(groups)
      groups.joins(groupings: [:assignment, student_memberships: [role: :end_user]])
            .where('assessments.id': params[:assignment_id])
            .pluck_to_hash(*DEFAULT_FIELDS, :membership_status, :user_id)
            .group_by { |h| h.slice(*DEFAULT_FIELDS) }
            .map { |k, v| k.merge(members: v.map { |h| h.except(*DEFAULT_FIELDS) }) }
    end

    def add_members
      if self.grouping.nil?
        # The group doesn't have a grouping associated with that assignment
        render 'shared/http_status', locals: {code: '422', message:
          'The group is not involved with that assignment'}, status: 422
        return
      end

      students = current_course.students.joins(:end_user).where('users.user_name': params[:members])
      students.each do |student|
        set_membership_status = grouping.student_memberships.empty? ?
          StudentMembership::STATUSES[:inviter] :
          StudentMembership::STATUSES[:accepted]
        grouping.invite(student.user_name, set_membership_status, true)
        grouping.reload
      end

      render 'shared/http_status', locals: { code: '200', message:
        HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
    end

    # Update the group's marks for the given assignment.
    def update_marks
      result = self.grouping&.current_submission_used&.get_latest_result
      return page_not_found('No submission exists for that group') if result.nil?

      # We shouldn't be able to update marks if marking is already complete.
      if result.marking_state == Result::MARKING_STATES[:complete]
        render 'shared/http_status', locals: { code: '404', message:
          'Marking for that submission is already completed' }, status: 404
        return
      end
      matched_criteria = assignment.criteria.where(name: params.keys)
      if matched_criteria.empty?
        render 'shared/http_status', locals: { code: '404', message:
          'No criteria were found that match that request.' }, status: 404
        return
      end

      matched_criteria.each do |crit|
        mark_to_change = result.marks.find_or_initialize_by(criterion_id: crit.id)
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

    def create_extra_marks
      result = self.grouping&.current_submission_used&.get_latest_result
      return page_not_found('No submission exists for that group') if result.nil?

      begin
        ExtraMark.create!(result_id: result.id, extra_mark: params[:extra_marks],
                          description: params[:description], unit: ExtraMark::POINTS)
      rescue ActiveRecord::RecordInvalid => e
        # Some error occurred
        render 'shared/http_status', locals: { code: '500', message:
            e.message }, status: 500
        return
      end
      result.update_total_mark
      render 'shared/http_status', locals: { code: '200', message:
          'Extra mark created successfully' }, status: 200
    end

    def remove_extra_marks
      result = self.grouping&.current_submission_used&.get_latest_result
      return page_not_found('No submission exists for that group') if result.nil?
      extra_mark = ExtraMark.find_by(result_id: result.id,
                                     description: params[:description],
                                     extra_mark: params[:extra_marks])
      if extra_mark.nil?
        render 'shared/http_status', locals: { code: '404', message:
            'No such Extra Mark exist for that result' }, status: 404
        return
      end
      begin
        extra_mark.destroy
      rescue ActiveRecord::RecordNotDestroyed => e
        # Some other error occurred
        render 'shared/http_status', locals: { code: '500', message:
            e.message }, status: 500
        return
      end
      result.update_total_mark
      # Successfully deleted the Extra Mark; render success
      render 'shared/http_status', locals: { code: '200', message:
          'Extra mark removed successfully' }, status: 200
    end

    def annotations
      if record # this is a member route
        grouping_relation = assignment.groupings.where(group_id: record.id)
      else # this is a collection route
        grouping_relation = assignment.groupings
      end

      pluck_keys = ['annotations.type as type',
                    'annotation_texts.content as content',
                    'submission_files.filename as filename',
                    'submission_files.path as path',
                    'annotations.page as page',
                    'group_id',
                    'annotation_categories.annotation_category_name as category',
                    'annotations.creator_id as creator_id',
                    'annotation_texts.creator_id as content_creator_id',
                    'annotations.line_end as line_end',
                    'annotations.line_start as line_start',
                    'annotations.column_start as column_start',
                    'annotations.column_end as column_end',
                    'annotations.x1 as x1',
                    'annotations.y1 as y1',
                    'annotations.x2 as x2',
                    'annotations.y2 as y2']

      annotations = grouping_relation.left_joins(current_submission_used:
                                              [submission_files:
                                                 [annotations:
                                                    [annotation_text: :annotation_category]]])
                                     .where('assessment_id': params[:assignment_id])
                                     .where.not('annotations.id': nil)
                                     .pluck_to_hash(*pluck_keys)
      respond_to do |format|
        format.xml do
          render xml: annotations.to_xml(root: 'annotations', skip_types: 'true')
        end
        format.json do
          render json: annotations.to_json
        end
      end
    end

    def add_annotations
      result = self.grouping&.current_result
      return page_not_found('No submission exists for that group') if result.nil?

      force_complete = params.fetch(:force_complete, false)
      # We shouldn't be able to update annotations if marking is already complete, unless forced.
      if result.marking_state == Result::MARKING_STATES[:complete] && !force_complete
        return page_not_found('Marking for that submission is already completed')
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

        annotation_texts << {
          content: annot_params[:content],
          annotation_category_id: annotation_category_id,
          creator_id: current_role.id,
          last_editor_id: current_role.id
        }
        annotations << {
          line_start: annot_params[:line_start],
          line_end: annot_params[:line_end],
          column_start: annot_params[:column_start],
          column_end: annot_params[:column_end],
          annotation_text_id: nil,
          submission_file_id: submission_file.id,
          creator_id: current_role.id,
          creator_type: current_role.type,
          is_remark: !result.remark_request_submitted_at.nil?,
          annotation_number: count + i,
          result_id: result.id
        }
      end
      imported = AnnotationText.insert_all! annotation_texts
      imported.rows.zip(annotations) do |t, a|
        a[:annotation_text_id] = t[0]
      end
      TextAnnotation.insert_all! annotations
      render 'shared/http_status', locals: { code: '200', message:
        HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
    end

    # Return key:value pairs of group_name:group_id
    def group_ids_by_name
      reversed = assignment.groups.pluck(:group_name, :id).to_h
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
      result = self.grouping&.current_submission_used&.get_latest_result
      return page_not_found('No submission exists for that group') if result.nil?
      result.marking_state = params[:marking_state]
      if result.save
        render 'shared/http_status', locals: { code: '200', message:
            HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
      else
        render 'shared/http_status', locals: { code: '500', message:
            result.errors.full_messages.first }, status: 500
      end
    end

    private

    def assignment
      @assignment ||= Assignment.find_by_id(params[:assignment_id])
    end

    def grouping
      @grouping ||= record.grouping_for_assignment(assignment.id)
    end

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
