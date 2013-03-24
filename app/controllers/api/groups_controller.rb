module Api

  # Allows for listing Markus groups for a particular assignment.
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class GroupsController < MainApiController
    # Define default fields to display for index and show methods
    @@default_fields = [:id, :group_name, :created_at, :updated_at, :first_name,
                        :last_name, :user_name, :membership_status, 
                        :student_memberships];

    # Requires: nothing
    # Optional: filter, fields
    def index
      # Check if it's a numeric string
      if !!(params[:assignment_id] =~ /^[0-9]+$/)
        assignment = Assignment.find_by_id(params[:assignment_id])
        if assignment.nil?
          # No assignment with that id
          render 'shared/http_status', :locals => {:code => '404', :message =>
            'No assignment exists with that id'}, :status => 404
          return
        else
          collection = Group.joins(:assignments).where(:assignments => 
            {:id => params[:assignment_id]})
          groups = get_collection(Group, collection)
          fields = fields_to_render(@@default_fields)

          students = include_students(fields)

          respond_to do |format|
            format.any{render :xml => groups.to_xml(:only => fields, :root => 
              'groups', :skip_types => 'true', :include => students)}
            format.json{render :json => groups.to_json(:only => fields, 
              :include => students)}
          end
        end
      else
        # Invalid params if it wasn't a numeric string
        render 'shared/http_status', :locals => {:code => '422', :message =>
          'Invalid id'}, :status => 422
        return
      end
    end

    # Requires: id
    # Optional: filter, fields
    def show
      # Check if it's a numeric string
      if !!(params[:assignment_id] =~ /^[0-9]+$/) && !!(params[:id] =~ /^[0-9]+$/)
        assignment = Assignment.find_by_id(params[:assignment_id])
        if assignment.nil?
          # No assignment with that id
          render 'shared/http_status', :locals => {:code => '404', :message =>
            'No assignment exists with that id'}, :status => 404
          return
        else
          group = Group.find_by_id(params[:id])
          if group.nil?
            # No group exists with that id
            render 'shared/http_status', :locals => {:code => '404', :message =>
              'No group exists with that id'}, :status => 404
            return
          else
            if !group.grouping_for_assignment(params[:assignment_id]).nil?
              fields = fields_to_render(@@default_fields)

              students = include_students(fields)

              respond_to do |format|
                format.any{render :xml => group.to_xml(:only => fields, :root => 
                  'group', :skip_types => 'true', :include => students)}
                format.json{render :json => group.to_json(:only => fields, 
                  :include => students)}
              end
            else
              # The group doesn't have a grouping associated with that assignment
              render 'shared/http_status', :locals => {:code => '422', :message =>
                'Group is not involved with that assignment'}, :status => 422
              return
            end
          end
        end
      else
        # Invalid params if it wasn't a numeric string
        render 'shared/http_status', :locals => {:code => '422', :message =>
          'Invalid id'}, :status => 422
        return
      end
    end

    # Requires nothing, does nothing
    def create
      # Don't allow creating groups through the api
      render 'shared/http_status', :locals => {:code => '404', :message =>
        HttpStatusHelper::ERROR_CODE['message']['404'] }, :status => 404
    end

    # Requires nothing, does nothing
    def update
      # Don't allow updating groups
      render 'shared/http_status', :locals => {:code => '404', :message =>
        HttpStatusHelper::ERROR_CODE['message']['404'] }, :status => 404
    end

    # Requires nothing, does nothing
    def destroy
      # Don't allow deleting groups
      render 'shared/http_status', :locals => {:code => '404', :message =>
        HttpStatusHelper::ERROR_CODE['message']['404'] }, :status => 404
    end

    # Include student_memberships and user info if required
    def include_students(fields)
      students = {}
      if fields.include?(:student_memberships)
        students = {:student_memberships => {:include => :user}}
      end
    end

  end # end GroupsController
end
