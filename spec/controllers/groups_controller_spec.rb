describe GroupsController do
  # TODO: add 'role is from a different course' shared tests to each route test below
  let(:grouping) { create(:grouping) }
  let(:group) { grouping.group }
  let(:assignment) { grouping.assignment }
  let(:course) { assignment.course }

  describe 'instructor access' do
    let(:instructor) { create(:instructor) }

    describe 'GET #new' do
      before do
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
          before do
            allow(assignment).to receive(:add_group)
              .with(group_name)
              .and_raise("Group #{group_name} already exists")

            get_as instructor, :new,
                   params: { course_id: course.id, assignment_id: assignment, new_group_name: group_name }
          end

          it 'assigns the error message to flash[:error]' do
            expect(flash[:error]).to contain_message("Group #{group_name} already exists")
          end
        end
      end
    end

    describe 'DELETE #remove_group' do
      before do
        allow(Grouping).to receive(:where).and_return([grouping])
      end

      context 'when grouping has no submissions' do
        before do
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
        before do
          allow(grouping).to receive(:has_submission?).and_return(true)

          delete_as instructor, :remove_group,
                    params: { course_id: course.id, grouping_id: [grouping.id], assignment_id: assignment }
        end

        it 'should have an error message in the flash queue' do
          expect(flash[:error]).to be_present
        end

        it 'assigns empty array to @removed_groupings' do
          expect(assigns(:removed_groupings)).to be_empty
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

    describe '#rename_group' do
      # rubocop:disable RSpec/LetSetup
      let!(:another_assignment) { create(:assignment) }
      let!(:placeholder_group) do
        create(:group, assignments: [another_assignment], group_name: 'placeholder_group')
      end
      # rubocop:enable RSpec/LetSetup

      context 'default grouping' do
        it 'should rename a group' do
          # The id param expects grouping id, not group id.
          expect do
            post_as instructor, :rename_group, params: {
              course_id: course.id,
              assignment_id: assignment.id,
              id: grouping.id,
              new_groupname: 'renamed'
            }
          end.to change { group.reload.group_name }.from('group1').to('renamed')
        end
      end

      context 'grouping with submitted files' do
        let!(:another_grouping) { create(:grouping, assignment: assignment) }

        before do
          @file = create(:assignment_file, assignment: assignment)
          another_grouping.group.access_repo do |repo|
            txn = repo.get_transaction('markus')
            assignment_folder = File.join(assignment.repository_folder, File::SEPARATOR)
            begin
              txn.add(File.join(assignment_folder, 'Shapes.java'), 'shapes content', 'text/plain')
              repo.commit(txn)
            end
          end
        end

        it 'flashes an error' do
          post_as instructor, :rename_group, params: {
            course_id: course.id,
            assignment_id: assignment.id,
            id: another_grouping.id,
            new_groupname: 'placeholder_group'
          }

          expect(flash[:error]).to have_message(I18n.t('groups.group_name_already_in_use_diff_assignment'))
        end
      end

      context 'grouping with a submission but no files' do
        let!(:another_grouping) { create(:grouping_with_inviter_and_submission, assignment: assignment) }

        it 'flashes an error' do
          post_as instructor, :rename_group, params: {
            course_id: course.id,
            assignment_id: assignment.id,
            id: another_grouping.id,
            new_groupname: 'placeholder_group'
          }

          expect(flash[:error]).to have_message(I18n.t('groups.group_name_already_in_use_diff_assignment'))
        end
      end
    end

    describe '#valid_grouping' do
      let(:unapproved_grouping) { create(:grouping_with_inviter, instructor_approved: false) }
      let(:approved_grouping) { create(:grouping_with_inviter, instructor_approved: true) }

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
      let(:approved_grouping) { create(:grouping_with_inviter, instructor_approved: true) }
      let(:unapproved_grouping) { create(:grouping_with_inviter, instructor_approved: false) }

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
      before do
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

    describe '#assign_scans' do
      let!(:assignment) { create(:assignment_for_scanned_exam) }

      context 'when grouping_id is passed as argument' do
        context 'when current_submission_used is nil' do
          let!(:grouping) { create(:grouping, assignment: assignment) }

          it 'redirects back with a warning flash message' do
            get_as instructor, :assign_scans, params: { course_id: course.id,
                                                        assignment_id: grouping.assignment.id,
                                                        grouping_id: grouping.id }
            expect(flash[:warning]).not_to be_blank
            expect(response).to redirect_to(course_assignment_groups_path(assignment.course, assignment))
          end
        end

        context 'when current submission is not nil' do
          let!(:grouping) { create(:grouping_with_inviter_and_submission, assignment: assignment) }

          it 'maps the data hash to correct values' do
            names = grouping.non_rejected_student_memberships.map do |u|
              u.user.display_name
            end

            data_expected = {
              group_name: grouping.group.group_name,
              grouping_id: grouping.id,
              students: names,
              num_total: 1,
              num_valid: 1,
              ocr_match: nil,
              ocr_suggestions: []
            }

            get_as instructor, :assign_scans, params: { course_id: course.id,
                                                        assignment_id: grouping.assignment.id,
                                                        grouping_id: grouping.id }

            expect(controller.view_assigns['data']).to eq(data_expected)
          end

          context 'when valid number of groupings equal total groupings' do
            it 'flashes a success message' do
              get_as instructor, :assign_scans, params: { course_id: course.id,
                                                          assignment_id: grouping.assignment.id,
                                                          grouping_id: grouping.id }

              expect(flash[:success]).not_to be_blank
            end
          end

          context 'when valid number of groupings do not equal total groupings' do
            let!(:submission) { create(:submission, submission_version_used: true) }
            let!(:grouping) do
              create(:grouping,
                     assignment: assignment,
                     submissions: [submission],
                     current_submission_used: submission)
            end

            it 'does not flash a success message' do
              get_as instructor, :assign_scans, params: { course_id: course.id,
                                                          assignment_id: grouping.assignment.id,
                                                          grouping_id: grouping.id }

              expect(flash[:success]).to be_blank
            end
          end

          context 'when COVER.pdf file does not exist' do
            it 'flashes a warning' do
              get_as instructor, :assign_scans, params: { course_id: course.id,
                                                          assignment_id: grouping.assignment.id,
                                                          grouping_id: grouping.id }
              expect(flash[:warning]).not_to be_blank
            end
          end

          context 'when COVER.pdf file exists' do
            let!(:file) { create(:submission_file, submission: grouping.submissions[0], filename: 'COVER.pdf') }

            it 'sets the data hash with the correct filelink' do
              grouping.submissions[0].update!(submission_files: [file])
              get_as instructor, :assign_scans, params: { course_id: course.id,
                                                          assignment_id: grouping.assignment.id,
                                                          grouping_id: grouping.id }

              expect(controller.view_assigns['data'][:filelink]).to eq(download_course_assignment_groups_path(
                                                                         assignment.course, assignment,
                                                                         select_file_id: file.id,
                                                                         show_in_browser: true
                                                                       ))
              expect(flash[:warning]).to be_nil
            end
          end

          context 'when OCR match data exists' do
            let!(:student1) { create(:student, course: course) }
            let!(:student2) { create(:student, course: course) }

            before do
              # Create exam template (required for assignment)
              create(:exam_template_midterm, assignment: assignment)

              student1.user.update!(id_number: '1234567890', user_name: 'student1')
              student2.user.update!(id_number: '1234567891', user_name: 'student2')

              # Store OCR match data for unmatched grouping
              OcrMatchService.store_match(
                grouping.id,
                '1234567890',
                'id_number',
                matched: false,
                student_id: nil
              )
            end

            it 'includes OCR match data in response' do
              get_as instructor, :assign_scans, params: { course_id: course.id,
                                                          assignment_id: grouping.assignment.id,
                                                          grouping_id: grouping.id }

              data = controller.view_assigns['data']
              expect(data[:ocr_match]).not_to be_nil
              expect(data[:ocr_match][:parsed_value]).to eq '1234567890'
              expect(data[:ocr_match][:field_type]).to eq 'id_number'
              expect(data[:ocr_match][:matched]).to be false
            end

            it 'includes OCR suggestions in response' do
              get_as instructor, :assign_scans, params: { course_id: course.id,
                                                          assignment_id: grouping.assignment.id,
                                                          grouping_id: grouping.id }

              data = controller.view_assigns['data']
              expect(data[:ocr_suggestions]).not_to be_empty
              expect(data[:ocr_suggestions].first[:id]).to eq student1.id
              expect(data[:ocr_suggestions].first[:id_number]).to eq '1234567890'
              expect(data[:ocr_suggestions].first[:similarity]).to be > 90.0
            end
          end

          context 'when no OCR match data exists' do
            let(:exam_template) { create(:exam_template_midterm, assignment: assignment) }

            before { exam_template }

            it 'includes nil ocr_match in response' do
              get_as instructor, :assign_scans, params: { course_id: course.id,
                                                          assignment_id: grouping.assignment.id,
                                                          grouping_id: grouping.id }

              data = controller.view_assigns['data']
              expect(data[:ocr_match]).to be_nil
              expect(data[:ocr_suggestions]).to be_empty
            end
          end

          context 'when assignment has no exam template' do
            it 'includes nil ocr_match in response' do
              get_as instructor, :assign_scans, params: { course_id: course.id,
                                                          assignment_id: grouping.assignment.id,
                                                          grouping_id: grouping.id }

              data = controller.view_assigns['data']
              expect(data[:ocr_match]).to be_nil
              expect(data[:ocr_suggestions]).to be_empty
            end
          end
        end
      end

      context 'when grouping_id is not passed as an argument' do
        context 'when next_grouping is nil' do
          before { create(:grouping, assignment: assignment, instructor_approved: true) }

          context 'when not all submissions collected' do
            it 'redirects back with a warning flash message' do
              get_as instructor, :assign_scans, params: { course_id: course.id,
                                                          assignment_id: assignment.id }
              expect(flash[:warning]).not_to be_blank
              expect(response).to redirect_to(course_assignment_groups_path(assignment.course, assignment))
            end
          end

          context 'when all submissions collected' do
            let!(:grouping_with_submission) { create(:grouping_with_inviter_and_submission) }

            it 'redirects to index' do
              get_as instructor, :assign_scans, params: { course_id: course.id,
                                                          assignment_id: grouping_with_submission.assignment.id }

              expect(flash[:warning]).to be_nil
              expect(response).to redirect_to(action: 'index')
            end
          end
        end

        context 'when current_submission_used is nil' do
          let!(:grouping) { create(:grouping, assignment: assignment) }

          it 'redirects back with a warning flash message' do
            get_as instructor, :assign_scans, params: { course_id: course.id,
                                                        assignment_id: grouping.assignment.id }
            expect(flash[:warning]).not_to be_blank
            expect(response).to redirect_to(course_assignment_groups_path(assignment.course, assignment))
          end
        end

        context 'when current_submission_used and next_grouping is not nil' do
          let!(:submission) { create(:submission, submission_version_used: true) }
          let!(:grouping) do
            create(:grouping,
                   assignment: assignment,
                   submissions: [submission],
                   current_submission_used: submission)
          end

          it 'maps the data hash to correct values' do
            names = []

            data_expected = {
              group_name: grouping.group.group_name,
              grouping_id: grouping.id,
              students: names,
              num_total: 1,
              num_valid: 0,
              ocr_match: nil,
              ocr_suggestions: []
            }

            get_as instructor, :assign_scans, params: { course_id: course.id,
                                                        assignment_id: grouping.assignment.id }

            expect(controller.view_assigns['data']).to eq(data_expected)
          end

          context 'when COVER.pdf file does not exist' do
            it 'flashes a warning' do
              get_as instructor, :assign_scans, params: { course_id: course.id,
                                                          assignment_id: grouping.assignment.id }
              expect(flash[:warning]).not_to be_blank
            end
          end

          context 'when COVER.pdf file exists' do
            let(:file) { create(:submission_file, submission: submission, filename: 'COVER.pdf') }

            it 'sets the data hash with the correct filelink' do
              submission.update!(submission_files: [file])
              get_as instructor, :assign_scans, params: { course_id: course.id,
                                                          assignment_id: grouping.assignment.id }

              expect(controller.view_assigns['data'][:filelink]).to eq(download_course_assignment_groups_path(
                                                                         assignment.course, assignment,
                                                                         select_file_id: file.id,
                                                                         show_in_browser: true
                                                                       ))
              expect(flash[:warning]).to be_nil
            end
          end
        end
      end
    end

    describe '#upload', keep_memory_repos: true do
      before do
        FileUtils.rm_rf(Rails.root.join('data/test/repos/group_0001/'))

        # since the git
        allow(Repository.get_class).to receive(:purge_all).and_return nil

        # Setup for Git Repository
        allow(Settings.repository).to receive(:type).and_return('git')

        @assignment = create(:assignment)

        # Create students corresponding to the file_good
        @student_user_names = %w[c8shosta c5bennet]
        @student_user_names.each do |name|
          create(:student, user: create(:end_user, user_name: name))
        end
      end

      it_behaves_like 'a controller supporting upload' do
        let(:params) { { course_id: course.id, assignment_id: @assignment.id } }
      end

      ['.csv', '', '.pdf'].each do |extension|
        ext_string = extension.empty? ? 'none' : extension
        it "accepts a valid CSV file with extension '#{ext_string}'" do
          expect do
            post_as instructor, :upload, params: { course_id: course.id,
                                                   assignment_id: @assignment.id,
                                                   upload_file: fixture_file_upload("groups/form_good#{extension}",
                                                                                    'text/csv') }
          end.to have_enqueued_job(CreateGroupsJob)
          expect(response).to have_http_status(:found)
          expect(flash[:error]).to be_blank
          expect(response).to redirect_to(action: 'index')
        end
      end

      it 'does not accept files with invalid columns' do
        post_as instructor, :upload, params: { course_id: course.id,
                                               assignment_id: @assignment.id,
                                               upload_file: fixture_file_upload('groups/form_invalid_column.csv',
                                                                                'text/csv') }

        expect(response).to have_http_status(:found)
        expect(flash[:error]).not_to be_blank
        expect(response).to redirect_to(action: 'index')
      end
    end

    describe '#create_groups_when_students_work_alone' do
      # Create students
      let!(:students) { create_list(:student, 5) }

      context 'when assignment.group_max = 1' do
        let!(:assignment) { create(:assignment) }

        it 'creates groups for individual students' do
          data = students.map { |record| [record.user_name, record.user_name] }

          get_as instructor, :create_groups_when_students_work_alone,
                 params: { course_id: course.id, assignment_id: assignment.id },
                 format: 'js'

          expected_args = ->(job_args) do
            assignment_arg, data_arg = job_args
            expect(assignment_arg).to eq(assignment)
            expect(data_arg).to match_array(data)
          end

          assert_enqueued_with(job: CreateGroupsJob, args: expected_args)
          expect(flash[:error]).to be_blank
        end

        it 'responds with _poll_job template' do
          get_as instructor, :create_groups_when_students_work_alone,
                 params: { course_id: course.id, assignment_id: assignment.id },
                 format: 'js'
          expect(response).to render_template('shared/_poll_job')
        end

        it 'responds with appropriate status' do
          get_as instructor, :create_groups_when_students_work_alone,
                 params: { course_id: course.id, assignment_id: assignment.id },
                 format: 'js'
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when assignment.group_max > 1' do
        let(:assignment) { create(:assignment, assignment_properties_attributes: { group_max: 4 }) }

        it 'does not create groups' do
          expect do
            get_as instructor, :create_groups_when_students_work_alone,
                   params: { course_id: course.id, assignment_id: assignment.id }, format: 'js'
          end.not_to have_enqueued_job(CreateGroupsJob)
        end

        it 'responds with appropriate status' do
          get_as instructor, :create_groups_when_students_work_alone,
                 params: { course_id: course.id, assignment_id: assignment.id },
                 format: 'js'
          expect(response).to have_http_status(:ok)
        end

        it 'responds with _poll_job template' do
          get_as instructor, :create_groups_when_students_work_alone,
                 params: { course_id: course.id, assignment_id: assignment.id },
                 format: 'js'
          expect(response).to render_template('shared/_poll_job')
        end
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

      before do
        @assignment = create(:assignment)

        @group = create(:group, course: @assignment.course)

        @student1 = create(:student, user: create(:end_user, user_name: 'c8shosta'))
        @student2 = create(:student, user: create(:end_user, user_name: 'c5bennet'))

        grouping = Grouping.new(assignment: @assignment, group: @group)
        grouping.save

        grouping.add_member(@student1, StudentMembership::STATUSES[:inviter])
        grouping.add_member(@student2, StudentMembership::STATUSES[:accepted])
      end

      it 'responds with appropriate status' do
        get_as instructor, :download_grouplist,
               params: { course_id: course.id, assignment_id: @assignment.id }, format: 'csv'
        expect(response).to have_http_status(:ok)
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
        let(:grouping) { create(:grouping_with_inviter) }
        let(:pending_student) { create(:student) }
        let(:accepted_student) { create(:student) }

        before do
          create(:student_membership, role: pending_student, grouping: grouping)
          create(:accepted_student_membership, role: accepted_student, grouping: grouping)
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
      let(:grouping) { create(:grouping_with_inviter) }

      it 'should validate groupings' do
        post_as instructor, :global_actions, params: { course_id: course.id,
                                                       assignment_id: grouping.assignment.id,
                                                       groupings: [grouping.id],
                                                       global_actions: 'valid' }
        expect(grouping.reload.instructor_approved).to be true
      end
    end

    describe '#invalidate_groupings' do
      let(:grouping) { create(:grouping_with_inviter, instructor_approved: true) }

      it 'should invalidate groupings' do
        post_as instructor, :global_actions, params: { course_id: course.id,
                                                       assignment_id: grouping.assignment.id,
                                                       groupings: [grouping.id],
                                                       global_actions: 'invalid' }

        expect(grouping.reload.instructor_approved).to be false
      end
    end

    describe '#delete_groupings' do
      let!(:grouping) { create(:grouping_with_inviter) }
      let!(:grouping_with_submission) { create(:grouping_with_inviter_and_submission) }

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
      let(:grouping) { create(:grouping_with_inviter) }
      let(:student1) { create(:student) }
      let(:student2) { create(:student) }

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
      let(:grouping) { create(:grouping_with_inviter) }
      let(:student1) { create(:student) }
      let(:student2) { create(:student) }

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
      let!(:users) do
        [create(:end_user, user_name: 'c9test1', first_name: 'first', last_name: 'last', id_number: '12345'),
         create(:end_user, user_name: 'zzz', first_name: 'zzz', last_name: 'zzz', id_number: '789'),
         create(:end_user, user_name: 'zz396', first_name: 'zzfirst', last_name: 'zzlast', id_number: '781034'),
         create(:end_user, user_name: 'c123hello', first_name: 'fhello', last_name: 'lhello', id_number: '1284923')]
      end
      let!(:students) do
        users.zip([false, false, false, true]).map do |u, hidden|
          create(:student, user: u, hidden: hidden)
        end
      end
      let(:expected) do
        [{ 'id' => students[0].id,
           'id_number' => students[0].id_number,
           'user_name' => students[0].user_name,
           'value' => "#{students[0].first_name} #{students[0].last_name}" }]
      end

      let(:expected_inactive) do
        [{ 'id' => students[3].id,
           'id_number' => students[3].id_number,
           'user_name' => students[3].user_name,
           'value' => "#{students[3].first_name} #{students[3].last_name} (inactive)" }]
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

      it 'returns matches for active students only' do
        post_as instructor, :get_names, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  assignment: assignment.id,
                                                  term: 'f',
                                                  format: :json }

        expect(response.parsed_body).to match_array expected
      end

      it 'returns matches for inactive students' do
        post_as instructor, :get_names, params: { course_id: course.id,
                                                  assignment_id: assignment.id,
                                                  assignment: assignment.id,
                                                  term: 'fhe',
                                                  format: :json,
                                                  display_inactive: true }

        expect(response.parsed_body).to match_array expected_inactive
      end

      context 'when users are already in groups' do
        before { create(:grouping_with_inviter, assignment: assignment, inviter: students[0]) }

        let(:assignment2) { create(:assignment) }
        let(:grouping2) { create(:grouping_with_inviter, assignment: assignment2, inviter: students[1]) }

        it 'does not match a student already in a grouping' do
          post_as instructor, :get_names, params: { course_id: course.id,
                                                    assignment_id: assignment.id,
                                                    assignment: assignment.id,
                                                    term: '123',
                                                    format: :json }
          expect(response.parsed_body).to be_empty
        end

        it 'does match students not in the group but in other assignment groups' do
          post_as instructor, :get_names, params: { course_id: course.id,
                                                    assignment_id: assignment.id,
                                                    assignment: assignment.id,
                                                    term: '789',
                                                    format: :json }

          expect(response.parsed_body).to match_array [
            { 'id' => students[1].id,
              'id_number' => students[1].id_number,
              'user_name' => students[1].user_name,
              'value' => "#{students[1].first_name} #{students[1].last_name}" }
          ]
        end
      end

      context 'when multiple students match' do
        let(:expected) do
          [{ 'id' => students[1].id,
             'id_number' => students[1].id_number,
             'user_name' => students[1].user_name,
             'value' => "#{students[1].first_name} #{students[1].last_name}" },
           { 'id' => students[2].id,
             'id_number' => students[2].id_number,
             'user_name' => students[2].user_name,
             'value' => "#{students[2].first_name} #{students[2].last_name}" }]
        end

        it 'returns multiple matches' do
          post_as instructor, :get_names, params: { course_id: course.id,
                                                    assignment_id: assignment.id,
                                                    assignment: assignment.id,
                                                    term: 'zz',
                                                    format: :json }

          expect(response.parsed_body).to match_array expected
        end
      end
    end

    describe '#assign_student_and_next' do
      let!(:assignment) { create(:assignment_for_scanned_exam) }
      let!(:student1) do
        create(:student,
               user: create(:end_user,
                            user_name: 'c9test1', first_name: 'first', last_name: 'last', id_number: '12345'))
      end
      let!(:grouping1) { create(:grouping, assignment: assignment) }

      before { create(:version_used_submission, grouping: grouping1) }

      context 'when there is another student and grouping' do
        before do
          create(:student,
                 user: create(:end_user, user_name: 'zzz', first_name: 'zzz', last_name: 'zzz', id_number: '789'))
          grouping2 = create(:grouping, assignment: assignment)
          create(:version_used_submission, grouping: grouping2)
        end

        it 'assigns a student to the grouping and returns the next one' do
          post_as instructor, :assign_student_and_next,
                  params: { course_id: course.id,
                            assignment_id: assignment.id,
                            assignment: assignment.id,
                            names: "#{student1.first_name} #{student1.last_name}",
                            s_id: student1.id,
                            g_id: grouping1.id,
                            format: :json }
          expect(grouping1.memberships.first.role).to eq student1
        end

        it 'assigns a student to the grouping and returns the next one based on names' do
          post_as instructor, :assign_student_and_next,
                  params: { course_id: course.id,
                            assignment_id: assignment.id,
                            assignment: assignment.id,
                            names: "#{student1.first_name} #{student1.last_name}",
                            g_id: grouping1.id,
                            format: :json }
          expect(grouping1.memberships.first.role).to eq student1
        end
      end

      it 'flashes an error if the student cannot be found' do
        post_as instructor, :assign_student_and_next, params: { course_id: course.id,
                                                                assignment_id: assignment.id,
                                                                assignment: assignment.id,
                                                                names: 'Student Whodoesntexist',
                                                                g_id: grouping1.id,
                                                                format: :json }
        expect(flash[:error]).not_to be_empty
      end

      it 'returns a not_found status if the student cannot be found' do
        post_as instructor, :assign_student_and_next, params: { course_id: course.id,
                                                                assignment_id: assignment.id,
                                                                assignment: assignment.id,
                                                                names: 'Student Whodoesntexist',
                                                                g_id: grouping1.id,
                                                                format: :json }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a not_found status if next grouping is nil' do
        post_as instructor, :assign_student_and_next, params: { course_id: course.id,
                                                                assignment_id: assignment.id,
                                                                assignment: assignment.id,
                                                                names: "#{student1.first_name} #{student1.last_name}",
                                                                s_id: student1.id,
                                                                g_id: grouping1.id,
                                                                format: :json }
        expect(response).to have_http_status(:not_found)
      end

      context 'when assigning inactive students' do
        let!(:inactive_student) do
          create(:student,
                 hidden: true,
                 user: create(:end_user,
                              user_name: 'inactive_student',
                              first_name: 'Inactive',
                              last_name: 'Student',
                              id_number: '99999'))
        end

        before do
          grouping2 = create(:grouping, assignment: assignment)
          create(:version_used_submission, grouping: grouping2)
        end

        it 'assigns an inactive student to the grouping when s_id is provided' do
          post_as instructor, :assign_student_and_next,
                  params: { course_id: course.id,
                            assignment_id: assignment.id,
                            assignment: assignment.id,
                            names: "#{inactive_student.first_name} #{inactive_student.last_name}",
                            s_id: inactive_student.id,
                            g_id: grouping1.id,
                            format: :json }
          expect(grouping1.memberships.first.role).to eq inactive_student
        end

        it 'assigns an inactive student to the grouping by name only' do
          post_as instructor, :assign_student_and_next,
                  params: { course_id: course.id,
                            assignment_id: assignment.id,
                            assignment: assignment.id,
                            names: "#{inactive_student.first_name} #{inactive_student.last_name}",
                            g_id: grouping1.id,
                            format: :json }
          expect(grouping1.memberships.first.role).to eq inactive_student
        end
      end

      context 'testing student selection logic when s_id and names may differ' do
        let!(:student2) do
          create(:student,
                 user: create(:end_user,
                              user_name: 'c9test2',
                              first_name: 'Different',
                              last_name: 'Person',
                              id_number: '67890'))
        end

        before do
          grouping2 = create(:grouping, assignment: assignment)
          create(:version_used_submission, grouping: grouping2)
        end

        it 'uses name lookup when no dropdown selection is made (student.nil?)' do
          post_as instructor, :assign_student_and_next,
                  params: { course_id: course.id,
                            assignment_id: assignment.id,
                            assignment: assignment.id,
                            names: "#{student1.first_name} #{student1.last_name}",
                            g_id: grouping1.id,
                            format: :json }
          expect(grouping1.memberships.first.role).to eq student1
        end

        it 'prioritizes manually edited name over dropdown selection when they differ' do
          # Simulates: user selected student2 from dropdown, then manually edited the text to student1's name
          post_as instructor, :assign_student_and_next,
                  params: { course_id: course.id,
                            assignment_id: assignment.id,
                            assignment: assignment.id,
                            names: "#{student1.first_name} #{student1.last_name}",
                            s_id: student2.id,
                            g_id: grouping1.id,
                            format: :json }
          expect(grouping1.memberships.first.role).to eq student1
          expect(grouping1.memberships.map(&:role)).not_to include(student2)
        end

        it 'uses dropdown selection when it matches typed name' do
          post_as instructor, :assign_student_and_next,
                  params: { course_id: course.id,
                            assignment_id: assignment.id,
                            assignment: assignment.id,
                            names: "#{student2.first_name} #{student2.last_name}",
                            s_id: student2.id,
                            g_id: grouping1.id,
                            format: :json }
          expect(grouping1.memberships.first.role).to eq student2
        end
      end
    end
  end

  describe 'student access' do
    before do
      @current_student = create(:student, user: create(:end_user, user_name: 'c9test2'))
      @student = create(:student, user: create(:end_user, user_name: 'c9test1'))
      @assignment = create(:assignment,
                           due_date: 1.day.from_now,
                           assignment_properties_attributes: { student_form_groups: true, group_max: 4 })
    end

    describe 'POST #create' do
      before do
        post_as @student, :create, params: { course_id: course.id, assignment_id: assignment }
      end

      it 'should respond with redirect' do
        expect(subject).to respond_with(:redirect)
      end
    end

    describe 'DELETE #destroy' do
      let(:grouping) { create(:grouping) }

      before do
        delete_as @student, :destroy, params: { course_id: course.id, assignment_id: assignment.id, id: grouping.id }
      end

      it 'should respond with success' do
        expect(subject).to respond_with(:redirect)
      end
    end

    describe 'POST #invite_member' do
      before do
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
        @another_student = create(:student, user: create(:end_user, user_name: 'c9test3'))
        expect do
          post_as @current_student, :invite_member,
                  params: { course_id: course.id, invite_member: "#{@student.user_name},#{@another_student.user_name}",
                            assignment_id: @assignment.id }
        end.to change { ActionMailer::Base.deliveries.count }.by(2)
      end

      it 'should not send an email to every student invited to a grouping if some have emails disabled' do
        @another_student = create(:student,
                                  user: create(:end_user, user_name: 'c9test3'), receives_invite_emails: false)
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
        end.not_to(change { ActionMailer::Base.deliveries.count })
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
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'fails to accept when the invitation has already been accepted' do
        create(:accepted_student_membership, role: @current_student, grouping: grouping)
        post_as @current_student, :accept_invitation,
                params: { course_id: course.id, assignment_id: grouping.assessment_id, grouping_id: grouping.id }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'fails to accept when another invitation has already been accepted' do
        grouping2 = create(:grouping_with_inviter, assignment: grouping.assignment)
        create(:student_membership, role: @current_student, grouping: grouping)
        create(:accepted_student_membership, role: @current_student, grouping: grouping2)
        post_as @current_student, :accept_invitation,
                params: { course_id: course.id, assignment_id: grouping.assessment_id, grouping_id: grouping.id }
        expect(response).to have_http_status(:unprocessable_content)
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
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'fails to reject when there is no invitation' do
        post_as @current_student, :decline_invitation,
                params: { course_id: course.id, assignment_id: grouping.assessment_id, grouping_id: grouping.id }
        expect(response).to have_http_status(:unprocessable_content)
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
          expect(response).to have_http_status(:forbidden)
        end

        it 'fails to cancel a pending invitation for a different grouping' do
          grouping2 = create(:grouping_with_inviter, assignment: grouping.assignment)
          invitation = create(:accepted_student_membership, grouping: grouping2)
          post_as @current_student, :disinvite_member,
                  params: { course_id: course.id, assignment_id: grouping.assessment_id, membership: invitation.id }
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when the current student is not the inviter' do
        let(:grouping) { create(:grouping_with_inviter) }

        it 'fails to cancel a pending invitation' do
          create(:accepted_student_membership, grouping: grouping, role: @current_student)
          invitation = create(:student_membership, grouping: grouping)
          post_as @current_student, :disinvite_member,
                  params: { course_id: course.id, assignment_id: grouping.assessment_id, membership: invitation.id }
          expect(response).to have_http_status(:forbidden)
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
          expect(response).to have_http_status(:forbidden)
        end

        it 'fails to delete an accepted invitation' do
          invitation = create(:accepted_student_membership, grouping: grouping)
          post_as @current_student, :delete_rejected,
                  params: { course_id: course.id, assignment_id: grouping.assessment_id, membership: invitation.id }
          expect(response).to have_http_status(:forbidden)
        end

        it 'fails to cancel a rejected invitation for a different grouping' do
          grouping2 = create(:grouping_with_inviter, assignment: grouping.assignment)
          invitation = create(:rejected_student_membership, grouping: grouping2)
          post_as @current_student, :delete_rejected,
                  params: { course_id: course.id, assignment_id: grouping.assessment_id, membership: invitation.id }
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when the current student is not the inviter' do
        let(:grouping) { create(:grouping_with_inviter) }

        it 'fails to cancel a rejected invitation' do
          create(:rejected_student_membership, grouping: grouping, role: @current_student)
          invitation = create(:student_membership, grouping: grouping)
          post_as @current_student, :delete_rejected,
                  params: { course_id: course.id, assignment_id: grouping.assessment_id, membership: invitation.id }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe '#download_starter_file' do
    subject { get_as role, :download_starter_file, params: { course_id: course.id, assignment_id: assignment.id } }

    context 'an instructor' do
      let(:role) { create(:instructor) }

      it 'should respond with 403' do
        subject
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'a grader' do
      let(:role) { create(:ta) }

      it 'should respond with 403' do
        subject
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'a student' do
      let(:role) { create(:student) }
      let(:assignment) { create(:assignment) }
      let(:starter_file_group) { create(:starter_file_group_with_entries, assignment: assignment) }
      let(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: role) }

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

        it_behaves_like 'download starter files properly'
      end

      context 'when the grouping was created before any starter file groups' do
        before do
          grouping
          starter_file_group
        end

        it_behaves_like 'download starter files properly'
      end

      context 'when the assignment is hidden' do
        let(:assignment) { create(:assignment, is_hidden: true) }

        it 'should respond with 403' do
          grouping
          starter_file_group
          subject
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when the assignment is timed' do
        let(:assignment) { create(:timed_assignment) }

        context 'the grouping has started' do
          before do
            starter_file_group
            grouping.update!(start_time: 1.minute.ago)
          end

          it_behaves_like 'download starter files properly'
        end

        context 'when the deadline has already passed' do
          before do
            starter_file_group
            grouping
            assignment.update!(due_date: 1.minute.ago)
          end

          it_behaves_like 'download starter files properly'
        end

        context 'the grouping has not started yet' do
          before do
            starter_file_group
            grouping
          end

          it 'should respond with 403' do
            subject
            expect(response).to have_http_status(:forbidden)
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
      let(:role) { create(:instructor) }

      it 'should respond with 403' do
        subject
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'a grader' do
      let(:role) { create(:ta) }

      it 'should respond with 403' do
        subject
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'a student' do
      let(:role) { create(:student) }
      let(:assignment) { create(:assignment, assignment_properties_attributes: { vcs_submit: true }) }
      let(:starter_file_group) { create(:starter_file_group_with_entries, assignment: assignment) }
      let(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: role) }

      shared_examples 'populate starter files properly' do
        shared_examples 'write starter files to repo' do
          it 'populates the grouping repository with the correct content' do
            subject
            grouping.access_repo do |repo|
              rev = repo.get_latest_revision
              expect(rev.path_exists?(File.join(assignment.short_identifier, 'q1', 'q1.txt'))).to be true
              expect(rev.path_exists?(File.join(assignment.short_identifier, 'q2.txt'))).to be true
            end
          end

          it 'writes the correct content' do
            subject
            grouping.access_repo do |repo|
              rev_file = repo.get_latest_revision.files_at_path(assignment.short_identifier)['q2.txt']
              expect(repo.download_as_string(rev_file)).to eq 'q2 content'
            end
          end
        end

        context 'when the repo is empty' do
          it_behaves_like 'write starter files to repo'
        end

        context 'when some files already exist in the repo' do
          before do
            grouping.access_repo do |repo|
              txn = repo.get_transaction(role.user_name)
              txn.add_path(File.join(assignment.short_identifier, 'q1'))
              txn.add(File.join(assignment.short_identifier, 'q2.txt'), 'other_content', 'application/octet-stream')
              repo.commit(txn)
            end
          end

          it_behaves_like 'write starter files to repo'
        end
      end

      context 'when the grouping was created after any starter file groups' do
        before do
          starter_file_group
          grouping
        end

        it_behaves_like 'populate starter files properly'
      end

      context 'when the grouping was created before any starter file groups' do
        before do
          grouping
          starter_file_group
        end

        it_behaves_like 'populate starter files properly'
      end

      context 'when the assignment is hidden' do
        let(:assignment) { create(:assignment, is_hidden: true) }

        it 'should respond with 403' do
          grouping
          starter_file_group
          subject
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when the assignment does not allow version control submissions' do
        let(:assignment) { create(:assignment, assignment_properties_attributes: { vcs_submit: false }) }

        it 'should respond with 403' do
          grouping
          starter_file_group
          subject
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when the assignment is timed' do
        let(:assignment) { create(:timed_assignment, assignment_properties_attributes: { vcs_submit: true }) }

        context 'the grouping has started' do
          before do
            starter_file_group
            grouping.update!(start_time: 1.minute.ago)
          end

          it_behaves_like 'populate starter files properly'
        end

        context 'when the deadline has already passed' do
          before do
            starter_file_group
            grouping
            grouping.update!(start_time: 1.minute.ago)
            assignment.update!(due_date: 1.minute.ago)
          end

          it_behaves_like 'populate starter files properly'
        end

        context 'the grouping has not started yet' do
          before do
            starter_file_group
            grouping
          end

          it 'should respond with 403' do
            subject
            expect(response).to have_http_status(:forbidden)
          end
        end
      end
    end
  end
end
