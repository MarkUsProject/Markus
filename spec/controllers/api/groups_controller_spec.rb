describe Api::GroupsController do
  context 'An unauthenticated request' do
    before :each do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it 'should fail to authenticate a GET index request' do
      get :index, params: { assignment_id: 1 }
      expect(response.status).to eq(403)
    end

    it 'should fail to authenticate a GET show request' do
      get :show, params: { id: 1, assignment_id: 1 }
      expect(response.status).to eq(403)
    end

    it 'should fail to authenticate a POST create request' do
      post :create, params: { assignment_id: 1 }

      expect(response.status).to eq(403)
    end

    it 'should fail to authenticate a PUT update request' do
      put :create, params: { id: 1, assignment_id: 1 }
      expect(response.status).to eq(403)
    end

    it 'should fail to authenticate a DELETE destroy request' do
      delete :destroy, params: { id: 1, assignment_id: 1 }
      expect(response.status).to eq(403)
    end
  end
  context 'An authenticated request requesting' do
    let(:assignment) { create :assignment }
    let(:grouping) { create :grouping_with_inviter, assignment: assignment }
    before :each do
      admin = create :admin
      admin.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{admin.api_key.strip}"
    end
    context 'GET index' do
      context 'expecting an xml response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/xml'
        end
        context 'with a single grouping' do
          before :each do
            get :index, params: { assignment_id: grouping.assignment.id }
          end
          it 'should be successful' do
            expect(response.status).to eq(200)
          end
          it 'should return xml content' do
            expect(Hash.from_xml(response.body).dig('groups', 'group', 'id')).to eq(grouping.group.id.to_s)
          end
        end
        context 'with multiple assignments' do
          before :each do
            5.times { create :grouping_with_inviter, assignment: assignment }
            get :index, params: { assignment_id: assignment.id }
          end
          it 'should return xml content about all assignments' do
            expect(Hash.from_xml(response.body).dig('groups', 'group').length).to eq(5)
          end
        end
      end
      context 'expecting a json response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/json'
        end
        context 'with a single assignment' do
          before :each do
            get :index, params: { assignment_id: grouping.assignment.id }
          end
          it 'should be successful' do
            expect(response.status).to eq(200)
          end
          it 'should return json content' do
            expect(JSON.parse(response.body)&.first&.dig('id')).to eq(grouping.group.id)
          end
        end
        context 'with multiple groupings' do
          let(:groupings) { Array.new(5) { create :grouping_with_inviter, assignment: assignment } }
          it 'should return content about all groupings' do
            groupings
            get :index, params: { assignment_id: assignment.id }
            expect(JSON.parse(response.body).length).to eq(5)
          end
          it 'should return only filtered content' do
            gr = groupings.first
            get :index, params: { assignment_id: gr.assignment.id, filter: { group_name: gr.group.group_name } }
            expect(JSON.parse(response.body)&.first&.dig('id')).to eq(gr.group.id)
          end
          it 'should not return groups that match the filter from another assignment' do
            get :index, params: { assignment_id: create(:assignment).id,
                                  filter: { group_name: groupings.last.group.group_name } }
            expect(JSON.parse(response.body)).to be_empty
          end
          it 'should reject invalid filters' do
            get :index, params: { assignment_id: groupings.first.assignment.id, filter: { bad_filter: 'something' } }
            expect(response.status).to eq(422)
          end
        end
      end
    end
    context 'GET show' do
      context 'expecting an xml response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/xml'
        end
        context 'with a single grouping' do
          before :each do
            get :show, params: { id: grouping.group.id, assignment_id: grouping.assignment.id }
          end
          it 'should be successful' do
            expect(response.status).to eq(200)
          end
          it 'should return xml content' do
            expect(Hash.from_xml(response.body).dig('groups', 'group', 'id')).to eq(grouping.group.id.to_s)
          end
        end
      end
      context 'expecting a json response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/json'
        end
        context 'with a single assignment' do
          before :each do
            get :show, params: { id: grouping.group.id, assignment_id: grouping.assignment.id }
          end
          it 'should be successful' do
            expect(response.status).to eq(200)
          end
          it 'should return json content' do
            expect(JSON.parse(response.body)&.first&.dig('id')).to eq(grouping.group.id)
          end
        end
      end
      context 'requesting a non-existant assignment' do
        it 'should respond with 404' do
          get :show, params: { id: 9999, assignment_id: assignment.id }
          expect(response.status).to eq(404)
        end
      end
    end
    context 'POST add_new_members' do
      context 'when adding a student to an existing group with a member already' do
        let(:student) { create :student }
        before :each do
          post :add_members, params: { id: grouping.group.id,
                                       assignment_id: grouping.assignment.id,
                                       members: [student.user_name] }
        end
        it 'should respond with 200' do
          expect(response.status).to eq(200)
        end
        it 'should add the student with accepted status' do
          expect(grouping.accepted_students).to include(student)
          status = grouping.accepted_student_memberships.find_by(user_id: student.id).membership_status
          expect(status).to eq(StudentMembership::STATUSES[:accepted])
        end
      end
      context 'when adding a student to an existing group without a member already' do
        let(:grouping) { create :grouping, assignment: assignment }
        let(:student) { create :student }
        before :each do
          post :add_members, params: { id: grouping.group.id,
                                       assignment_id: grouping.assignment.id,
                                       members: [student.user_name] }
        end
        it 'should respond with 200' do
          expect(response.status).to eq(200)
        end
        it 'should add the student with inviter status' do
          expect(grouping.accepted_students).to include(student)
          status = grouping.accepted_student_memberships.find_by(user_id: student.id).membership_status
          expect(status).to eq(StudentMembership::STATUSES[:inviter])
        end
      end
      context 'when adding a student to a group without a grouping for this assignment' do
        let(:grouping) { create :grouping }
        let(:student) { create :student }
        before :each do
          post :add_members, params: { id: grouping.group.id,
                                       assignment_id: assignment.id,
                                       members: [student.user_name] }
        end
        it 'should respond with 422' do
          expect(response.status).to eq(422)
        end
        it 'should not add the student to the group' do
          expect(grouping.memberships).to be_empty
        end
      end
      context 'add multiple group members' do
        let(:students) { create_list(:student, 3) }
        before :each do
          post :add_members, params: { id: grouping.group.id,
                                       assignment_id: grouping.assignment.id,
                                       members: students.map(&:user_name) }
        end
        it 'should respond with 200' do
          expect(response.status).to eq(200)
        end
        it 'should add the students with accepted status' do
          statuses = grouping.accepted_student_memberships.where(user_id: students.map(&:id)).pluck(:membership_status)
          expect(statuses).to all(be == StudentMembership::STATUSES[:accepted])
        end
      end
    end
    context 'POST update_marks' do
      let(:criterion) { create(:flexible_criterion, assignment: assignment, max_mark: 10) }
      let(:submission) { create(:version_used_submission, grouping: grouping) }
      context 'when a grouping does not yet have a mark' do
        before :each do
          submission
          post :update_marks, params: { id: grouping.group.id,
                                        assignment_id: grouping.assignment.id,
                                        criterion.name => 4 }
          grouping.reload
        end
        it 'should respond with 200' do
          expect(response.status).to eq(200)
        end
        it 'should add a mark for a grouping' do
          result = submission.current_result
          expect(result.get_total_mark).to eq(4)
        end
      end
      context 'when a grouping does have a mark already' do
        before :each do
          mark = submission.current_result.marks.find_or_initialize_by(criterion_id: criterion.id)
          mark.mark = 10
          mark.save!
          post :update_marks, params: { id: grouping.group.id,
                                        assignment_id: grouping.assignment.id,
                                        criterion.name => 4 }
          grouping.reload
          submission.reload
        end
        it 'should respond with 200' do
          expect(response.status).to eq(200)
        end
        it 'should add a mark for a grouping' do
          result = submission.current_result
          expect(result.get_total_mark).to eq(4)
        end
      end
      context 'when a result is complete' do
        before :each do
          mark = submission.current_result.marks.find_or_initialize_by(criterion_id: criterion.id)
          mark.mark = 10
          mark.save!
          submission.current_result.update(marking_state: Result::MARKING_STATES[:complete])
          post :update_marks, params: { id: grouping.group.id,
                                        assignment_id: grouping.assignment.id,
                                        criterion.name => 4 }
          grouping.reload
          submission.reload
        end
        it 'should respond with 404' do
          expect(response.status).to eq(404)
        end
        it 'should add a mark for a grouping' do
          result = submission.current_result
          expect(result.get_total_mark).to eq(10)
        end
      end
    end
    context 'POST add_extra_marks' do
      let(:submission) { create(:version_used_submission, grouping: grouping) }
      context 'add extra_mark' do
        let(:old_mark) { submission.get_latest_result.total_mark }
        before :each do
          old_mark
          post :create_extra_marks, params: { assignment_id: grouping.assignment.id,
                                              id: grouping.group.id,
                                              extra_marks: 10.0,
                                              description: 'sample' }
          grouping.reload
        end
        it 'should add new extra mark' do
          result = submission.get_latest_result
          added_extra_mark = result.extra_marks.last
          expect(added_extra_mark.extra_mark).to eq(10.0)
        end
        it 'should update total_mark' do
          result = submission.get_latest_result
          new_total_mark = result.total_mark
          expect(old_mark + 10.0).to eq(new_total_mark)
        end
        it 'should respond with 200' do
          expect(response.status).to eq(200)
        end
      end
      context 'add wrong extra_mark' do
        let(:old_mark) { submission.get_latest_result.total_mark }
        before :each do
          old_mark
          post :create_extra_marks, params: { assignment_id: grouping.assignment.id,
                                              id: grouping.group.id,
                                              extra_marks: 'a',
                                              description: 'sample' }
          grouping.reload
        end
        it 'should respond with 500' do
          expect(response.status).to eq(500)
        end
        it 'should not update the total mark' do
          result = submission.get_latest_result
          new_total_mark = result.total_mark
          expect(old_mark).to eq(new_total_mark)
        end
      end
      describe 'when the arguments are invalid' do
        context 'When the assignment has no submission' do
          it 'should respond with 404' do
            post :create_extra_marks,
                 params: { assignment_id: grouping.assignment.id, id: grouping.group.id, extra_marks: 10.0,
                           description: 'sample' }
            expect(response.status).to eq(404)
          end
        end
        context 'when the assignment doest not exist ' do
          it 'should respond with 404' do
            post :create_extra_marks,
                 params: { assignment_id: 9999, id: grouping.group.id, extra_marks: 10.0, description: 'sample' }
            expect(response.status).to eq(404)
          end
        end
        context 'when the group does not exist' do
          it 'should respond with 404' do
            post :create_extra_marks,
                 params: { assignment_id: grouping.assignment.id, id: 9999, extra_marks: 10.0, description: 'sample' }
            expect(response.status).to eq(404)
          end
        end
      end
    end
    context 'DELETE remove_extra_marks' do
      describe 'when the arguments are invalid' do
        context 'When the assignment has no submission' do
          it 'should respond with 404' do
            delete :remove_extra_marks,
                   params: { assignment_id: grouping.assignment.id, id: grouping.group.id, extra_marks: 10.0,
                             description: 'sample' }
            expect(response.status).to eq(404)
          end
        end
        context 'when the assignment doest not exist ' do
          it 'should respond with 404' do
            delete :remove_extra_marks,
                   params: { assignment_id: 9999, id: grouping.group.id, extra_marks: 10.0, description: 'sample' }
            expect(response.status).to eq(404)
          end
        end
        context 'when the group does not exist' do
          it 'should respond with 404' do
            delete :remove_extra_marks,
                   params: { assignment_id: grouping.assignment.id, id: 9999, extra_marks: 10.0, description: 'sample' }
            expect(response.status).to eq(404)
          end
        end
      end
      describe 'when the arguments are valid' do
        let(:submission) { create(:version_used_submission, grouping: grouping) }
        let(:extra_mark) do
          create(:extra_mark_points, description: 'sample', extra_mark: 10.0, result: submission.get_latest_result)
        end
        context 'remove extra_mark' do
          let(:old_mark) { submission.get_latest_result.total_mark + extra_mark.extra_mark }
          before :each do
            old_mark
            delete :remove_extra_marks, params: { assignment_id: grouping.assignment.id,
                                                  id: grouping.group.id,
                                                  extra_marks: 10.0,
                                                  description: 'sample' }
            grouping.reload
          end
          it 'should update total mark' do
            result = submission.get_latest_result
            new_total_mark = result.total_mark
            expect(old_mark - 10.0).to eq(new_total_mark)
          end
          it 'should respond with 200' do
            expect(response.status).to eq(200)
          end
        end
        context 'remove extra_mark which does not exist' do
          let(:old_mark) { submission.get_latest_result.total_mark }
          before :each do
            old_mark
            delete :remove_extra_marks, params: { assignment_id: grouping.assignment.id,
                                                  id: grouping.group.id,
                                                  extra_marks: 2.0,
                                                  description: 'test' }
            grouping.reload
          end
          it 'should respond with 404' do
            expect(response.status).to eq(404)
          end
          it 'should not update the total mark' do
            result = submission.get_latest_result
            new_total_mark = result.total_mark
            expect(old_mark).to eq(new_total_mark)
          end
        end
      end
    end
    context 'GET group_ids_by_name' do
      context 'expecting a json response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/json'
          get :group_ids_by_name, params: { assignment_id: grouping.assignment.id }
        end
        it 'should respond with 200' do
          expect(response.status).to eq(200)
        end
        it 'should return a mapping from group names to ids' do
          expect(JSON.parse(response.body)).to eq(grouping.group.group_name => grouping.group.id)
        end
      end
      context 'expecting a xml response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/xml'
          get :group_ids_by_name, params: { assignment_id: grouping.assignment.id }
        end
        it 'should respond with 200' do
          expect(response.status).to eq(200)
        end
        it 'should return a mapping from group names to ids' do
          expect(Hash.from_xml(response.body)['groups']).to eq(grouping.group.group_name => grouping.group.id.to_s)
        end
      end
    end
    context 'POST update_marking_state' do
      let(:criterion) { create(:flexible_criterion, assignment: assignment, max_mark: 10) }
      let(:submission) { create(:version_used_submission, grouping: grouping) }
      context 'should complete a result' do
        before :each do
          submission.current_result.update(marking_state: Result::MARKING_STATES[:incomplete])
          post :update_marking_state, params: { id: grouping.group.id,
                                                assignment_id: grouping.assignment.id,
                                                marking_state: Result::MARKING_STATES[:complete] }
          submission.reload
        end
        it 'should respond with 200' do
          expect(response.status).to eq(200)
        end
        it 'should set the marking state to complete' do
          expect(submission.current_result.marking_state).to eq(Result::MARKING_STATES[:complete])
        end
      end
      context 'should un-complete a result' do
        before :each do
          submission.current_result.update(marking_state: Result::MARKING_STATES[:complete])
          post :update_marking_state, params: { id: grouping.group.id,
                                                assignment_id: grouping.assignment.id,
                                                marking_state: Result::MARKING_STATES[:incomplete] }
          submission.reload
        end
        it 'should respond with 200' do
          expect(response.status).to eq(200)
        end
        it 'should set the marking state to complete' do
          expect(submission.current_result.marking_state).to eq(Result::MARKING_STATES[:incomplete])
        end
      end
    end
  end
end
