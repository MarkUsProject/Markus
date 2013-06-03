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
        render 'shared/http_status', :locals => {:code => '404', :message =>
          'No assignment exists with that id'}, :status => 404
        return
      end

      collection = Group.joins(:assignments).where(:assignments => 
        {:id => params[:assignment_id]})
      groups = get_collection(Group, collection)
      fields = fields_to_render(@@default_fields)

      students = include_students(fields)

      respond_to do |format|
        format.xml{render :xml => groups.to_xml(:only => fields, :root => 
          'groups', :skip_types => 'true', :include => students)}
        format.json{render :json => groups.to_json(:only => fields, 
          :include => students)}
      end
    end

    # Returns a single group along with its attributes
    # Requires: assignment_id, id
    # Optional: fields
    def show
      # Error if no assignment exists with that id
      assignment = Assignment.find_by_id(params[:assignment_id])
      if assignment.nil?
        render 'shared/http_status', :locals => {:code => '404', :message =>
          'No assignment exists with that id'}, :status => 404
        return
      end

      # Error if no group exists with that id
      group = Group.find_by_id(params[:id])
      if group.nil?
        render 'shared/http_status', :locals => {:code => '404', :message =>
          'No group exists with that id'}, :status => 404
        return
      end

      if group.grouping_for_assignment(params[:assignment_id])
        # We found a grouping for that assignment
        fields = fields_to_render(@@default_fields)
        students = include_students(fields)

        respond_to do |format|
          format.xml{render :xml => group.to_xml(:only => fields, :root => 
            'group', :skip_types => 'true', :include => students)}
          format.json{render :json => group.to_json(:only => fields, 
            :include => students)}
        end
      else
        # The group doesn't have a grouping associated with that assignment
        render 'shared/http_status', :locals => {:code => '422', :message =>
          'The group is not involved with that assignment'}, :status => 422
      end
    end

    # Include student_memberships and user info if required
    def include_students(fields)
      if fields.include?(:student_memberships)
        {:student_memberships => {:include => :user}}
      end
    end

  end # end GroupsController
end
