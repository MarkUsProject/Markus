describe GroupsController do
  # TODO: add 'role is from a different course' shared tests to each route test below
  let(:grouping) { create(:grouping) }
  let(:assignment) { grouping.assignment }
  let(:course) { assignment.course }

  describe 'instructor access' do
    let(:instructor) { create :instructor }
    describe 'GET #new' do
      before :each do
        allow(Assignment).to receive(:find).and_return(assignment)
      end

      context 'when no group name is specified' do
        it 'adds a new group to assignment' do
          expect(assignment).to receive(:add_group)
            .with(nil)
            .and_return(grouping)
          get_as instructor, :new, params: { course_id: course.id, assignment_id: assignment }
        end
      end

      context 'when a group name is specified' do
        let(:group_name) { 'g2avatar' }

        context 'when group creation successful' do
          it 'creates a new group with specified name' do
            expect(assignment).to receive(:add_group)
              .with(group_name)
              .and_return(grouping)
            get_as instructor, :new,
                   params: { course_id: course.id, assignment_id: assignment, new_group_name: group_name }
          end
        end

        context 'when group creation unsuccessful' do
          before :each do
            allow(assignment).to receive(:add_group)
              .with(group_name)
              .and_raise("Group #{group_name} already exists")

            get_as instructor, :new,
                   params: { course_id: course.id, assignment_id: assignment, new_group_name: group_name }
          end

          it 'assigns the error message to flash[:error]' do
            expect(flash[:error]).to eq("Group #{group_name} already exists")
          end
        end
      end
    end

    describe 'DELETE #remove_group' do
      before :each do
        allow(Grouping).to receive(:where).and_return([grouping])
      end

      context 'when grouping has no submissions' do
        before :each do
          allow(grouping).to receive(:delete_grouping)
          allow(grouping).to receive(:has_submission?).and_return(false)
        end

        it 'should not flash an error message' do
          delete_as instructor, :remove_group,
                    params: { course_id: course.id, grouping_id: [grouping.id], assignment_id: assignment }
          expect(flash[:error]).to be_nil
        end

        it 'populates @removed_groupings with deleted groupings' do
          delete_as instructor, :remove_group,
                    params: { course_id: course.id, grouping_id: [grouping.id], assignment_id: assignment }
          expect(assigns(:removed_groupings)).to match_array([grouping])
        end

        it 'calls grouping.has_submission?' do
          expect(grouping).to receive(:has_submission?).and_return(false)
          delete_as instructor, :remove_group,
                    params: { course_id: course.id, grouping_id: [grouping.id], assignment_id: assignment }
        end

        it 'calls grouping.delete_groupings' do
          expect(grouping).to receive(:delete_grouping)
          delete_as instructor, :remove_group,
                    params: { course_id: course.id, grouping_id: [grouping.id], assignment_id: assignment }
        end

        it 'should attempt to update permissions file' do
          expect(Repository.get_class).to receive(:update_permissions_after)
          delete_as instructor, :remove_group,
                    params: { course_id: course.id, grouping_id: [grouping.id], assignment_id: assignment }
        end

        it 'should return the :ok status code' do
          delete_as instructor, :remove_group,
                    params: { course_id: course.id, grouping_id: [grouping.id], assignment_id: assignment }
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when grouping has submissions' do
        before :each do
          allow(grouping).to receive(:has_submission?).and_return(true)

          delete_as instructor, :remove_group,
                    params: { course_id: course.id, grouping_id: [grouping.id], assignment_id: assignment }
        end

        it 'should have an error message in the flash queue' do
          expect(flash[:error]).to be_present
        end

        it 'assigns empty array to @removed_groupings' do
          expect(assigns(:removed_groupings)).to match_array([])
        end

        it 'calls grouping.has_submission?' do
          expect(grouping).to receive(:has_submission?).and_return(true)
          delete_as instructor, :remove_group,
                    params: { course_id: course.id, grouping_id: [grouping.id], assignment_id: assignment }
        end

        it 'should return the :ok status code' do
          delete_as instructor, :remove_group,
                    params: { course_id: course.id, grouping_id: [grouping.id], assignment_id: assignment }
          expect(response).to have_http_status(:ok)
        end

        it 'should attempt to update permissions file' do
          expect(Repository.get_class).to receive(:update_permissions_after)
          delete_as instructor, :remove_group,
                    params: { course_id: course.id, grouping_id: [grouping.id], assignment_id: assignment }
        end
      end
    end

    describe '#rename_group'

    describe '#valid_grouping' do
      let(:unapproved_grouping) { create :grouping_with_inviter, instructor_approved: false }
      let(:approved_grouping) { create :grouping_with_inviter, instructor_approved: true }
      it 'validates a previously invalid grouping' do
        post_as instructor, :valid_grouping, params: { course_id: unapproved_grouping.course.id,
                                                       assignment_id: unapproved_grouping.assignment.id,
                                                       grouping_id: unapproved_grouping.id }
        expect(unapproved_grouping.reload.instructor_approved).to be true
      end
      it 'keeps a valid grouping valid' do
        post_as instructor, :valid_grouping, params: { course_id: approved_grouping.course.id,
                                                       assignment_id: approved_grouping.assignment.id,
                                                       grouping_id: approved_grouping.id }
        expect(approved_grouping.reload.instructor_approved).to be true
      end
    end

    describe '#invalid_grouping' do
      let(:approved_grouping) { create :grouping_with_inviter, instructor_approved: true }
      let(:unapproved_grouping) { create :grouping_with_inviter, instructor_approved: false }
      it 'invalidates a previously valid grouping' do
        post_as instructor, :invalid_grouping, params: { course_id: approved_grouping.course.id,
                                                         assignment_id: approved_grouping.assignment.id,
                                                         grouping_id: approved_grouping.id }
        expect(approved_grouping.reload.instructor_approved).to be false
      end
      it 'keeps a invalid grouping invalid' do
        post_as instructor, :invalid_grouping, params: { course_id: unapproved_grouping.course.id,
                                                         assignment_id: unapproved_grouping.assignment.id,
                                                         grouping_id: unapproved_grouping.id }
        expect(unapproved_grouping.reload.instructor_approved).to be false
      end
    end

    describe '#populate'
    describe '#populate_students'

    describe 'GET #index' do
      before :each do
        allow(Assignment).to receive(:find).and_return(assignment)
        get_as instructor, :index, params: { course_id: course.id, assignment_id: assignment }
      end

      it 'assigns the requested assignment to @assignment' do
        expect(assigns(:assignment)).to eq(assignment)
      end

      it 'renders the :index template' do
        expect(response).to render_template(:index)
      end
    end

    describe '#upload', keep_memory_repos: true do
      before :all do
        # remove a generated repo so repeated test runs function properly
        FileUtils.rm_r(
          File.join(::Rails.root.to_s, 'data/test/repos/group_0001', '/'),
          force: true
        )
      end

      before :each do
        # since the git
        allow(Repository.get_class).to receive(:purge_all).and_return nil

        # Setup for Git Repository
        allow(Settings.repository).to receive(:type).and_return('git')

        @assignment = create(:assignment)

        # Create students corresponding to the file_good
        @student_user_names = %w[c8shosta c5bennet]
        @student_user_names.each do |name|
          create(:student, end_user: create(:end_user, user_name: name))
        end
      end

      include_examples 'a controller supporting upload' do
        let(:params) { { course_id: course.id, assignment_id: @assignment.id } }
      end

      it 'accepts a valid file' do
        ActiveJob::Base.queue_adapter = :test
        expect do
          post_as instructor, :upload, params: { course_id: course.id,
                                                 assignment_id: @assignment.id,
                                                 upload_file: fixture_file_upload('groups/form_good.csv', 'text/csv') }
        end.to have_enqueued_job(CreateGroupsJob)
        expect(response.status).to eq(302)
        expect(flash[:error]).to be_blank
        expect(response).to redirect_to(action: 'index')
      end

      it 'does not accept files with invalid columns' do
        post_as instructor, :upload, params: { course_id: course.id,
                                               assignment_id: @assignment.id,
                                               upload_file: fixture_file_upload('groups/form_invalid_column.csv',
                                                                                'text/csv') }

        expect(response.status).to eq(302)
        expect(flash[:error]).to_not be_blank
        expect(response).to redirect_to(action: 'index')
      end
    end

    describe '#download_grouplist' do
      let(:csv_options) do
        {
          type: 'text/csv',
          filename: "#{@assignment.short_identifier}_group_list.csv",
          disposition: 'attachment'
        }
      end

      before :each do
        @assignment = FactoryBot.create(:assignment)

        @group = FactoryBot.create(:group, course: @assignment.course)

        @student1 = create(:student, end_user: create(:end_user, user_name: 'c8shosta'))
        @student2 = create(:student, end_user: create(:end_user, user_name: 'c5bennet'))

        grouping = Grouping.new(assignment: @assignment, group: @group)
        grouping.save

        grouping.add_member(@student1, StudentMembership::STATUSES[:inviter])
        grouping.add_member(@student2, StudentMembership::STATUSES[:accepted])
      end

      it 'responds with appropriate status' do
        get_as instructor, :download_grouplist,
               params: { course_id: course.id, assignment_id: @assignment.id }, format: 'csv'
        expect(response.status).to eq(200)
      end

      # parse header object to check for the right disposition
      it 'sets disposition as attachment' do
        get_as instructor, :download_grouplist,
               params: { course_id: course.id, assignment_id: @assignment.id }, format: 'csv'
        d = response.header['Content-Disposition'].split.first
        expect(d).to eq 'attachment;'
      end

      it 'expects a call to send_data' do
        csv_data = "#{@group.group_name},#{@student1.user_name},#{@student2.user_name}\n"
        expect(@controller).to receive(:send_data).with(csv_data, csv_options) {
          # to prevent a 'missing template' error
          @controller.head :ok
        }
        get_as instructor, :download_grouplist,
               params: { course_id: course.id, assignment_id: @assignment.id }, format: 'csv'
      end

      # parse header object to check for the right content type
      it 'returns text/csv type' do
        get_as instructor, :download_grouplist,
               params: { course_id: course.id, assignment_id: @assignment.id }, format: 'csv'
        expect(response.media_type).to eq 'text/csv'
      end

      # parse header object to check for the right file naming convention
      it 'filename passes naming conventions' do
        get_as instructor, :download_grouplist,
               params: { course_id: course.id, assignment_id: @assignment.id }, format: 'csv'
        filename = response.header['Content-Disposition']
                           .split[1].split('"').second
        expect(filename).to eq "#{@assignment.short_identifier}_group_list.csv"
      end
    end

    describe '#use_another_assignment_groups'
    describe '#global_actions' do
      describe 'remove_members' do
        let(:grouping) { create :grouping_with_inviter }
        let(:pending_student) { create :student }
        let(:accepted_student) { create :student }

        before :each do
          create :student_membership, role: pending_student, grouping: grouping
          create :accepted_student_membership, role: accepted_student, grouping: grouping
        end

        it 'should remove an accepted membership' do
          post_as instructor, :global_actions, params: { course_id: course.id, assignment_id: grouping.assignment.id,
                                                         groupings: [grouping.id],
                                                         students_to_remove: [accepted_student.id],
                                                         global_actions: 'unassign' }
          expect(grouping.memberships).not_to include(accepted_student)
        end

        it 'should remove a pending membership' do
          post_as instructor, :global_actions, params: { course_id: course.id, assignment_id: grouping.assignment.id,
                                                         groupings: [grouping.id],
                                                         students_to_remove: [pending_student.id],
                                                         global_actions: 'unassign' }
          expect(grouping.memberships).not_to include(pending_student)
        end
      end
    end

    describe '#validate_groupings' do
      let(:grouping) { create :grouping_with_inviter }

      it 'should validate groupings' do
        post_as instructor, :global_actions, params: { course_id: course.id,
                                                       assignment_id: grouping.assignment.id,
                                                       groupings: [grouping.id],
                                                       global_actions: 'valid' }
        expect(grouping.reload.instructor_approved).to be true
      end
    end

    describe '#invalidate_groupings' do
      let(:grouping) { create :grouping_with_inviter, instructor_approved: true }

      it 'should invalidate groupings' do
        post_as instructor, :global_actions, params: { course_id: course.id,
                                                       assignment_id: grouping.assignment.id,
                                                       groupings: [grouping.id],
                                                       global_actions: 'invalid' }

        expect(grouping.reload.instructor_approved).to be false
      end
    end

    describe '#delete_groupings' do
      let!(:grouping) { create :grouping_with_inviter }
      let!(:grouping_with_submission) { create :grouping_with_inviter_and_submission }

      it 'should delete groupings without submissions' do
        post_as instructor, :global_actions, params: { course_id: course.id,
                                                       assignment_id: grouping.assignment.id,
                                                       groupings: [grouping.id],
                                                       global_actions: 'delete' }

        expect(Grouping.all.size).to eq 1
      end

      it 'should not delete groupings with submissions' do
        post_as instructor, :global_actions, params: { course_id: course.id,
                                                       assignment_id: grouping_with_submission.assignment.id,
                                                       groupings: [grouping_with_submission.id],
                                                       global_actions: 'delete' }

        expect(Grouping.all.size).to eq 2
      end
    end

    describe '#add_members' do
      let(:grouping) { create :grouping_with_inviter }
      let(:student1) { create :student }
      let(:student2) { create :student }

      it 'adds multiple students to group' do
        post_as instructor, :global_actions, params: { course_id: course.id,
                                                       assignment_id: grouping.assignment.id,
                                                       groupings: [grouping],
                                                       students: [student1.id, student2.id],
                                                       global_actions: 'assign' }

        expect(grouping.students.size).to eq 3
      end
    end

    describe '#remove_members' do
      let(:grouping) { create :grouping_with_inviter }
      let(:student1) { create :student }
      let(:student2) { create :student }

      it 'should remove multiple students from group' do
        post_as instructor, :global_actions, params: { course_id: course.id,
                                                       assignment_id: grouping.assignment.id,
                                                       groupings: [grouping],
                                                       students: [student1.id, student2.id],
                                                       global_actions: 'assign' }

        post_as instructor, :global_actions, params: { course_id: course.id,
                                                       assignment_id: grouping.assignment.id,
                                                       groupings: [grouping],
                                                       students_to_remove: [student1.user_name, student2.user_name],
                                                       global_actions: 'unassign' }

        expect(grouping.reload.students.size).to eq 1
      end
    end

    describe 'GET #get_names' do
      let!(:assignment) { create(:assignment_for_scanned_exam) }
      let!(:student1) do
        create(:student,
               end_user: create(:end_user,
                                user_name: 'c9test1', first_name: 'first', last_name: 'last', id_number: '12345'))
      end
      let!(:student2) do
        create(:student,
               end_user: create(:end_user, user_name: 'zzz', first_name: 'zzz', last_name: 'zzz', id_number: '789'))
      end
      let(:expected) do
        [{ 'id' => student1.id,
           'id_number' => student1.id_number,
           'user_name' => student1.user_name,
           'value' => "#{student1.first_name} #{student1.last_name}" }]
      end

      it 'returns matches for user_name' do
        post_as instructor, :get_names, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  assignment: assignment.id,
                                                  term: 'c9',
                                                  format: :json }

        expect(response.parsed_body).to eq expected
      end

      it 'returns matches for first_name' do
        post_as instructor, :get_names, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  assignment: assignment.id,
                                                  term: 'fir',
                                                  format: :json }

        expect(response.parsed_body).to eq expected
      end

      it 'returns matches for last_name' do
        post_as instructor, :get_names, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  assignment: assignment.id,
                                                  term: 'la',
                                                  format: :json }

        expect(response.parsed_body).to eq expected
      end

      it 'returns matches for id_number' do
        post_as instructor, :get_names, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  assignment: assignment.id,
                                                  term: '123',
                                                  format: :json }

        expect(response.parsed_body).to eq expected
      end
    end
  end

  describe 'student access' do
    before :each do
      @current_student = create(:student, end_user: create(:end_user, user_name: 'c9test2'))
      @student = create(:student, end_user: create(:end_user, user_name: 'c9test1'))
      @assignment = create(:assignment,
                           due_date: 1.day.from_now,
                           assignment_properties_attributes: { student_form_groups: true, group_max: 4 })
    end

    describe 'POST #create' do
      before :each do
        post_as @student, :create, params: { course_id: course.id, assignment_id: assignment }
      end

      it 'should respond with redirect' do
        is_expected.to respond_with(:redirect)
      end
    end

    describe 'DELETE #destroy' do
      let(:grouping) { create :grouping }
      before :each do
        delete_as @student, :destroy, params: { course_id: course.id, assignment_id: assignment.id, id: grouping.id }
      end

      it 'should respond with success' do
        is_expected.to respond_with(:redirect)
      end
    end

    describe 'POST #invite_member' do
      before :each do
        create(:grouping_with_inviter, assignment: @assignment, inviter: @current_student)
      end

      around { |example| perform_enqueued_jobs(&example) }

      it 'should send an email to a single student if invited to a grouping' do
        expect do
          post_as @current_student, :invite_member,
                  params: { course_id: course.id, invite_member: @student.user_name, assignment_id: @assignment.id }
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'should send an email to every student invited to a grouping if more than one are' do
        @another_student = create(:student, end_user: create(:end_user, user_name: 'c9test3'))
        expect do
          post_as @current_student, :invite_member,
                  params: { course_id: course.id, invite_member: "#{@student.user_name},#{@another_student.user_name}",
                            assignment_id: @assignment.id }
        end.to change { ActionMailer::Base.deliveries.count }.by(2)
      end
      it 'should not send an email to every student invited to a grouping if some have emails disabled' do
        @another_student = create(:student,
                                  end_user: create(:end_user, user_name: 'c9test3'), receives_invite_emails: false)
        expect do
          post_as @current_student, :invite_member,
                  params: { course_id: course.id, invite_member: "#{@student.user_name},#{@another_student.user_name}",
                            assignment_id: @assignment.id }
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
      it 'should not send an email to a single student if invited to a grouping and they have emails disabled' do
        @student.update!(receives_invite_emails: false)
        expect do
          post_as @current_student, :invite_member,
                  params: { course_id: course.id, invite_member: @student.user_name, assignment_id: @assignment.id }
        end.to change { ActionMailer::Base.deliveries.count }.by(0)
      end
    end

    describe '#accept_invitation' do
      let!(:grouping) { create(:grouping_with_inviter) }
      it 'accepts a pending invitation' do
        invitation = create(:student_membership, role: @current_student, grouping: grouping)
        post_as @current_student, :accept_invitation,
                params: { course_id: course.id, assignment_id: grouping.assessment_id, grouping_id: grouping.id }
        expect(invitation.reload.membership_status).to eq StudentMembership::STATUSES[:accepted]
      end

      it 'accepts a rejected invitation' do
        invitation = create(:rejected_student_membership, role: @current_student, grouping: grouping)
        post_as @current_student, :accept_invitation,
                params: { course_id: course.id, assignment_id: grouping.assessment_id, grouping_id: grouping.id }
        expect(invitation.reload.membership_status).to eq StudentMembership::STATUSES[:accepted]
      end

      it 'fails to accept when there is no invitation' do
        post_as @current_student, :accept_invitation,
                params: { course_id: course.id, assignment_id: grouping.assessment_id, grouping_id: grouping.id }
        assert_response :unprocessable_entity
      end

      it 'fails to accept when the invitation has already been accepted' do
        create(:accepted_student_membership, role: @current_student, grouping: grouping)
        post_as @current_student, :accept_invitation,
                params: { course_id: course.id, assignment_id: grouping.assessment_id, grouping_id: grouping.id }
        assert_response :unprocessable_entity
      end

      it 'fails to accept when another invitation has already been accepted' do
        grouping2 = create(:grouping_with_inviter, assignment: grouping.assignment)
        create(:student_membership, role: @current_student, grouping: grouping)
        create(:accepted_student_membership, role: @current_student, grouping: grouping2)
        post_as @current_student, :accept_invitation,
                params: { course_id: course.id, assignment_id: grouping.assessment_id, grouping_id: grouping.id }
        assert_response :unprocessable_entity
      end

      it 'rejects other pending invitations' do
        create(:student_membership, role: @current_student, grouping: grouping)
        3.times do |_|
          new_grouping = create(:grouping_with_inviter, assignment: grouping.assignment)
          create(:student_membership, role: @current_student, grouping: new_grouping)
        end
        post_as @current_student, :accept_invitation,
                params: { course_id: course.id, assignment_id: grouping.assessment_id, grouping_id: grouping.id }
        expect(@current_student.student_memberships.size).to eq 4
        @current_student.student_memberships.each do |membership|
          if membership.grouping_id == grouping.id
            expect(membership.membership_status).to eq StudentMembership::STATUSES[:accepted]
          else
            expect(membership.membership_status).to eq StudentMembership::STATUSES[:rejected]
          end
        end
      end
    end

    describe '#decline_invitation' do
      let!(:grouping) { create(:grouping_with_inviter) }

      it 'rejects a pending invitation' do
        invitation = create(:student_membership, role: @current_student, grouping: grouping)
        post_as @current_student, :decline_invitation,
                params: { course_id: course.id, assignment_id: grouping.assessment_id, grouping_id: grouping.id }
        expect(invitation.reload.membership_status).to eq StudentMembership::STATUSES[:rejected]
      end

      it 'fails to reject when the invitation has already been accepted' do
        create(:accepted_student_membership, role: @current_student, grouping: grouping)
        post_as @current_student, :decline_invitation,
                params: { course_id: course.id, assignment_id: grouping.assessment_id, grouping_id: grouping.id }
        assert_response :unprocessable_entity
      end

      it 'fails to reject when there is no invitation' do
        post_as @current_student, :decline_invitation,
                params: { course_id: course.id, assignment_id: grouping.assessment_id, grouping_id: grouping.id }
        assert_response :unprocessable_entity
      end
    end

    describe '#disinvite_member' do
      context 'when the current student is the inviter' do
        let(:grouping) { create(:grouping_with_inviter, inviter: @current_student) }

        it 'cancels a pending invitation' do
          invitation = create(:student_membership, grouping: grouping)
          post_as @current_student, :disinvite_member,
                  params: { course_id: course.id, assignment_id: grouping.assessment_id, membership: invitation.id }
          expect(grouping.student_memberships.size).to eq 1
        end

        it 'fails to cancel an accepted invitation' do
          invitation = create(:accepted_student_membership, grouping: grouping)
          post_as @current_student, :disinvite_member,
                  params: { course_id: course.id, assignment_id: grouping.assessment_id, membership: invitation.id }
          assert_response :forbidden
        end

        it 'fails to cancel a pending invitation for a different grouping' do
          grouping2 = create(:grouping_with_inviter, assignment: grouping.assignment)
          invitation = create(:accepted_student_membership, grouping: grouping2)
          post_as @current_student, :disinvite_member,
                  params: { course_id: course.id, assignment_id: grouping.assessment_id, membership: invitation.id }
          assert_response :forbidden
        end
      end

      context 'when the current student is not the inviter' do
        let(:grouping) { create(:grouping_with_inviter) }

        it 'fails to cancel a pending invitation' do
          create(:accepted_student_membership, grouping: grouping, role: @current_student)
          invitation = create(:student_membership, grouping: grouping)
          post_as @current_student, :disinvite_member,
                  params: { course_id: course.id, assignment_id: grouping.assessment_id, membership: invitation.id }
          assert_response :forbidden
        end
      end
    end

    describe '#delete_rejected' do
      context 'when the current student is the inviter' do
        let(:grouping) { create(:grouping_with_inviter, inviter: @current_student) }

        it 'cancels a rejected invitation' do
          invitation = create(:rejected_student_membership, grouping: grouping)
          post_as @current_student, :delete_rejected,
                  params: { course_id: course.id, assignment_id: grouping.assessment_id, membership: invitation.id }
          expect(grouping.student_memberships.size).to eq 1
        end

        it 'fails to delete a pending invitation' do
          invitation = create(:student_membership, grouping: grouping)
          post_as @current_student, :delete_rejected,
                  params: { course_id: course.id, assignment_id: grouping.assessment_id, membership: invitation.id }
          assert_response :forbidden
        end

        it 'fails to delete an accepted invitation' do
          invitation = create(:accepted_student_membership, grouping: grouping)
          post_as @current_student, :delete_rejected,
                  params: { course_id: course.id, assignment_id: grouping.assessment_id, membership: invitation.id }
          assert_response :forbidden
        end

        it 'fails to cancel a rejected invitation for a different grouping' do
          grouping2 = create(:grouping_with_inviter, assignment: grouping.assignment)
          invitation = create(:rejected_student_membership, grouping: grouping2)
          post_as @current_student, :delete_rejected,
                  params: { course_id: course.id, assignment_id: grouping.assessment_id, membership: invitation.id }
          assert_response :forbidden
        end
      end

      context 'when the current student is not the inviter' do
        let(:grouping) { create(:grouping_with_inviter) }

        it 'fails to cancel a rejected invitation' do
          create(:rejected_student_membership, grouping: grouping, role: @current_student)
          invitation = create(:student_membership, grouping: grouping)
          post_as @current_student, :delete_rejected,
                  params: { course_id: course.id, assignment_id: grouping.assessment_id, membership: invitation.id }
          assert_response :forbidden
        end
      end
    end
  end

  describe '#download_starter_file' do
    subject { get_as role, :download_starter_file, params: { course_id: course.id, assignment_id: assignment.id } }
    context 'an instructor' do
      let(:role) { create :instructor }
      it 'should respond with 403' do
        subject
        expect(response).to have_http_status(403)
      end
    end
    context 'a grader' do
      let(:role) { create :ta }
      it 'should respond with 403' do
        subject
        expect(response).to have_http_status(403)
      end
    end
    context 'a student' do
      let(:role) { create :student }
      let(:assignment) { create :assignment }
      let(:starter_file_group) { create :starter_file_group_with_entries, assignment: assignment }
      let(:grouping) { create :grouping_with_inviter, assignment: assignment, inviter: role }

      shared_examples 'download starter files properly' do
        it 'should send a zip file containing the correct content' do
          expect(controller).to receive(:send_file) do |file_path|
            Zip::File.open(Rails.root + file_path) do |zipfile|
              expect(zipfile.entries.map(&:name)).to contain_exactly('q1/', 'q1/q1.txt', 'q2.txt')
              expect(zipfile.find_entry('q1/q1.txt').get_input_stream.read.strip).to eq 'q1 content'
              expect(zipfile.find_entry('q2.txt').get_input_stream.read.strip).to eq 'q2 content'
            end
          end
          subject
        end
      end
      context 'when the grouping was created after any starter file groups' do
        before do
          starter_file_group
          grouping
        end
        include_examples 'download starter files properly'
      end

      context 'when the grouping was created before any starter file groups' do
        before do
          grouping
          starter_file_group
        end
        include_examples 'download starter files properly'
      end

      context 'when the assignment is hidden' do
        let(:assignment) { create :assignment, is_hidden: true }
        it 'should respond with 403' do
          grouping
          starter_file_group
          subject
          expect(response).to have_http_status(403)
        end
      end

      context 'when the assignment is timed' do
        let(:assignment) { create :timed_assignment }
        context 'the grouping has started' do
          before do
            starter_file_group
            grouping.update!(start_time: 1.minute.ago)
          end
          include_examples 'download starter files properly'
        end
        context 'when the deadline has already passed' do
          before do
            starter_file_group
            grouping
            assignment.update!(due_date: 1.minute.ago)
          end
          include_examples 'download starter files properly'
        end
        context 'the grouping has not started yet' do
          before do
            starter_file_group
            grouping
          end
          it 'should respond with 403' do
            subject
            expect(response).to have_http_status(403)
          end
        end
      end
    end
  end

  describe '#populate_repo_with_starter_files' do
    subject do
      get_as role, :populate_repo_with_starter_files,
             params: { course_id: course.id, assignment_id: assignment.id }
    end
    context 'an instructor' do
      let(:role) { create :instructor }
      it 'should respond with 403' do
        subject
        expect(response).to have_http_status(403)
      end
    end
    context 'a grader' do
      let(:role) { create :ta }
      it 'should respond with 403' do
        subject
        expect(response).to have_http_status(403)
      end
    end
    context 'a student' do
      let(:role) { create :student }
      let(:assignment) { create :assignment, assignment_properties_attributes: { vcs_submit: true } }
      let(:starter_file_group) { create :starter_file_group_with_entries, assignment: assignment }
      let(:grouping) { create :grouping_with_inviter, assignment: assignment, inviter: role }

      shared_examples 'populate starter files properly' do
        it 'populates the grouping repository with the correct content' do
          subject
          grouping.access_repo do |repo|
            rev = repo.get_latest_revision
            expect(rev.path_exists?(File.join(assignment.short_identifier, 'q1', 'q1.txt'))).to be true
            expect(rev.path_exists?(File.join(assignment.short_identifier, 'q2.txt'))).to be true
          end
        end
      end
      context 'when the grouping was created after any starter file groups' do
        before do
          starter_file_group
          grouping
        end
        include_examples 'populate starter files properly'
      end

      context 'when the grouping was created before any starter file groups' do
        before do
          grouping
          starter_file_group
        end
        include_examples 'populate starter files properly'
      end

      context 'when the assignment is hidden' do
        let(:assignment) { create :assignment, is_hidden: true }
        it 'should respond with 403' do
          grouping
          starter_file_group
          subject
          expect(response).to have_http_status(403)
        end
      end

      context 'when the assignment does not allow version control submissions' do
        let(:assignment) { create :assignment, assignment_properties_attributes: { vcs_submit: false } }
        it 'should respond with 403' do
          grouping
          starter_file_group
          subject
          expect(response).to have_http_status(403)
        end
      end

      context 'when the assignment is timed' do
        let(:assignment) { create :timed_assignment, assignment_properties_attributes: { vcs_submit: true } }
        context 'the grouping has started' do
          before do
            starter_file_group
            grouping.update!(start_time: 1.minute.ago)
          end
          include_examples 'populate starter files properly'
        end
        context 'when the deadline has already passed' do
          before do
            starter_file_group
            grouping
            grouping.update!(start_time: 1.minute.ago)
            assignment.update!(due_date: 1.minute.ago)
          end
          include_examples 'populate starter files properly'
        end
        context 'the grouping has not started yet' do
          before do
            starter_file_group
            grouping
          end
          it 'should respond with 403' do
            subject
            expect(response).to have_http_status(403)
          end
        end
      end
    end
  end
end
