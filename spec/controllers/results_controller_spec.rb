describe ResultsController do
  let(:assignment) { create :assignment }
  let(:student) { create :student, grace_credits: 2 }
  let(:admin) { create :admin }
  let(:ta) { create :ta }
  let(:grouping) { create :grouping_with_inviter, assignment: assignment, inviter: student }
  let(:submission) { create :version_used_submission, grouping: grouping }
  let(:incomplete_result) { create :incomplete_result, submission: submission }
  let(:complete_result) { create :complete_result, submission: submission }
  let(:submission_file) { create :submission_file, submission: submission }
  let(:rubric_mark) { create :rubric_mark, result: incomplete_result }
  let(:flexible_mark) { create :flexible_mark, result: incomplete_result }

  SAMPLE_FILE_CONTENT = 'sample file content'.freeze
  SAMPLE_ERROR_MESSAGE = 'sample error message'.freeze
  SAMPLE_COMMENT = 'sample comment'.freeze
  SAMPLE_FILE_NAME = 'file.java'.freeze

  after(:each) do
    destroy_repos
  end

  def self.test_assigns_not_nil(key)
    it "should assign #{key}" do
      expect(assigns key).not_to be_nil
    end
  end

  def self.test_assigns_nil(key)
    it "should not assign #{key}" do
      expect(assigns(key)).to be_nil
    end
  end

  def self.test_redirect_no_login(route_name)
    it "should be redirected from #{route_name}" do
      method(ROUTES[route_name]).call(route_name, params: { assignment_id: 1, submission_id: 1, id: 1 })
      expect(response).to redirect_to action: 'login', controller: 'main'
    end
  end

  def self.test_no_flash
    it 'should not display any flash messages' do
      expect(flash).to be_empty
    end
  end

  def self.test_unauthorized(route_name)
    it "should not be authorized to access #{route_name}" do
      method(ROUTES[route_name]).call(route_name, params: { assignment_id: assignment.id,
                                                            submission_id: submission.id,
                                                            id: incomplete_result.id })
      expect(response).to have_http_status(:missing)
    end
  end

  shared_examples 'download files' do
    context 'downloading a file' do
      context 'without permission' do
        before :each do
          allow_any_instance_of(ResultsController).to receive(:authorized_to_download?).and_return false
          get :download, params: { assignment_id: assignment.id,
                                   submission_id: submission.id,
                                   id: incomplete_result.id }
        end
        it { expect(response).to have_http_status(:missing) }
        test_no_flash
      end
      context 'with permission' do
        before :each do
          allow_any_instance_of(ResultsController).to receive(:authorized_to_download?).and_return true
        end
        context 'and without any file errors' do
          before :each do
            allow_any_instance_of(SubmissionFile).to receive(:retrieve_file).and_return SAMPLE_FILE_CONTENT
            get :download, params: { assignment_id: assignment.id,
                                     submission_id: submission.id,
                                     select_file_id: submission_file.id,
                                     id: incomplete_result.id }
          end
          it { expect(response).to have_http_status(:success) }
          test_no_flash
          it 'should have the correct content type' do
            expect(response.header['Content-Type']).to eq 'application/octet-stream'
          end
          it 'should show the file content in the response body' do
            expect(response.body).to eq SAMPLE_FILE_CONTENT
          end
        end
        context 'and with a file error' do
          before :each do
            allow_any_instance_of(SubmissionFile).to receive(:retrieve_file).and_raise SAMPLE_ERROR_MESSAGE
            get :download, params: { assignment_id: assignment.id,
                                     submission_id: submission.id,
                                     select_file_id: submission_file.id,
                                     id: incomplete_result.id }
          end
          it { expect(response).to have_http_status(:redirect) }
          it 'should display a flash error' do
            expect(extract_text(flash[:error][0])).to eq SAMPLE_ERROR_MESSAGE
          end
        end
        context 'and with a supported image file shown in browser' do
          before :each do
            allow_any_instance_of(SubmissionFile).to receive(:is_supported_image?).and_return true
            allow_any_instance_of(SubmissionFile).to receive(:retrieve_file).and_return SAMPLE_FILE_CONTENT
            get :download, params: { assignment_id: assignment.id,
                                     submission_id: submission.id,
                                     select_file_id: submission_file.id,
                                     id: incomplete_result.id,
                                     show_in_browser: true }
          end
          it { expect(response).to have_http_status(:success) }
          test_no_flash
          it 'should have the correct content type' do
            expect(response.header['Content-Type']).to eq 'image'
          end
          it 'should show the file content in the response body' do
            expect(response.body).to eq SAMPLE_FILE_CONTENT
          end
        end
      end
    end
  end

  shared_examples 'shared ta and admin tests' do
    include_examples 'download files'
    context 'accessing next_grouping' do
      it 'should redirect when current grouping has a submission' do
        allow_any_instance_of(Grouping).to receive(:has_submission).and_return true
        get :next_grouping, params: { assignment_id: assignment.id, submission_id: submission.id,
                                      grouping_id: grouping.id, id: incomplete_result.id }
        expect(response).to have_http_status(:redirect)
      end
      it 'should redirect when current grouping does not have a submission' do
        allow_any_instance_of(Grouping).to receive(:has_submission).and_return false
        get :next_grouping, params: { assignment_id: assignment.id, submission_id: submission.id,
                                      grouping_id: grouping.id, id: incomplete_result.id }
        expect(response).to have_http_status(:redirect)
      end
    end
    context 'accessing toggle_marking_state' do
      context 'with a complete result' do
        before :each do
          post :toggle_marking_state, params: { assignment_id: assignment.id, submission_id: submission.id,
                                                id: complete_result.id }, xhr: true
        end
        it { expect(response).to have_http_status(:success) }
        # TODO: test that the grade distribution is refreshed
      end
    end
    context 'accessing download_zip' do
      before :each do
        grouping.group.access_repo do |repo|
          txn = repo.get_transaction('test')
          path = File.join(assignment.repository_folder, SAMPLE_FILE_NAME)
          txn.add(path, SAMPLE_FILE_CONTENT, '')
          repo.commit(txn)
          @submission = Submission.generate_new_submission(grouping, repo.get_latest_revision)
        end
        file = SubmissionFile.find_by_submission_id(@submission.id)
        @annotation = TextAnnotation.create  line_start: 1,
                                             line_end: 2,
                                             column_start: 1,
                                             column_end: 2,
                                             submission_file_id: file.id,
                                             is_remark: false,
                                             annotation_number: @submission.annotations.count + 1,
                                             annotation_text: create(:annotation_text, user: admin),
                                             result: complete_result,
                                             creator: admin
        file_name_snippet = grouping.group.access_repo do |repo|
          "#{assignment.short_identifier}_#{grouping.group.group_name}_r#{repo.get_latest_revision.revision_identifier}"
        end
        @file_path_ann = File.join 'tmp', "#{file_name_snippet}_ann.zip"
        @file_path = File.join 'tmp', "#{file_name_snippet}.zip"
        submission_file_dir = "#{assignment.repository_folder}-#{grouping.group.repo_name}"
        @submission_file_path = File.join(submission_file_dir, SAMPLE_FILE_NAME)
      end
      after :each do
        FileUtils.rm_f @file_path_ann
        FileUtils.rm_f @file_path
      end
      context 'and including annotations' do
        before :each do
          get :download_zip, params: {  assignment_id: assignment.id,
                                        submission_id: @submission.id,
                                        id: @submission.id,
                                        grouping_id: grouping.id,
                                        include_annotations: 'true' }
        end
        after :each do
          FileUtils.rm_f @file_path_ann
        end
        it { expect(response).to have_http_status(:success) }
        it 'should have make the correct content type' do
          expect(response.header['Content-Type']).to eq 'application/zip'
        end
        it 'should create a zip file' do
          File.exist? @file_path_ann
        end
        it 'should create a zip file containing the submission file' do
          Zip::File.open(@file_path_ann) do |zip_file|
            expect(zip_file.find_entry(@submission_file_path)).not_to be_nil
          end
        end
        it 'should include the annotations in the file output' do
          Zip::File.open(@file_path_ann) do |zip_file|
            expect(zip_file.read(@submission_file_path)).to include(@annotation.annotation_text.content)
          end
        end
      end
      context 'and not including annotations' do
        before :each do
          get :download_zip, params: {  assignment_id: assignment.id,
                                        submission_id: @submission.id,
                                        id: @submission.id,
                                        grouping_id: grouping.id,
                                        include_annotations: 'false' }
        end
        after :each do
          FileUtils.rm_f @file_path
        end
        it { expect(response).to have_http_status(:success) }
        it 'should have make the correct content type' do
          expect(response.header['Content-Type']).to eq 'application/zip'
        end
        it 'should create a zip file' do
          File.exist? @file_path
        end
        it 'should create a zip file containing the submission file' do
          Zip::File.open(@file_path) do |zip_file|
            expect(zip_file.find_entry(@submission_file_path)).not_to be_nil
          end
        end
        it 'should not include the annotations in the file output' do
          Zip::File.open(@file_path) do |zip_file|
            expect(zip_file.read(@submission_file_path)).not_to include(@annotation.annotation_text.content)
          end
        end
      end
    end
    context 'accessing update_mark' do
      it 'should report an updated mark' do
        patch :update_mark, params: { assignment_id: assignment.id, submission_id: submission.id,
                                      id: incomplete_result.id, markable_id: rubric_mark.markable_id,
                                      markable_type: rubric_mark.markable_type,
                                      mark: 1 }, xhr: true
        expect(JSON.parse(response.body)[:num_marked]).to be_nil
      end
      it { expect(response).to have_http_status(:redirect) }
      context 'but cannot save the mark' do
        before :each do
          allow_any_instance_of(Mark).to receive(:save).and_return false
          allow_any_instance_of(ActiveModel::Errors).to receive(:full_messages).and_return [SAMPLE_ERROR_MESSAGE]
          patch :update_mark, params: { assignment_id: assignment.id, submission_id: submission.id,
                                        id: incomplete_result.id, markable_id: rubric_mark.markable_id,
                                        markable_type: rubric_mark.markable_type,
                                        mark: 1 }, xhr: true
        end
        it { expect(response).to have_http_status(:bad_request) }
        it 'should report the correct error message' do
          expect(response.body).to match SAMPLE_ERROR_MESSAGE
        end
      end
    end
    context 'accessing view_mark' do
      before :each do
        get :view_marks, params: { assignment_id: assignment.id, submission_id: submission.id,
                                   id: incomplete_result.id }, xhr: true
      end
      it { expect(response).to have_http_status(:success) }
    end
    context 'accessing add_extra_mark' do
      context 'but cannot save the mark' do
        before :each do
          allow_any_instance_of(ExtraMark).to receive(:save).and_return false
          @old_mark = submission.get_latest_result.total_mark
          post :add_extra_mark, params: { assignment_id: assignment.id, submission_id: submission.id,
                                          id: submission.get_latest_result.id,
                                          extra_mark: { extra_mark: 1 } }, xhr: true
        end
        it { expect(response).to have_http_status(:bad_request) }
        it 'should not update the total mark' do
          expect(@old_mark).to eq(submission.get_latest_result.total_mark)
        end
      end
      context 'and can save the mark' do
        before :each do
          allow_any_instance_of(ExtraMark).to receive(:save).and_call_original
          @old_mark = submission.get_latest_result.total_mark
          post :add_extra_mark, params: { assignment_id: assignment.id, submission_id: submission.id,
                                          id: submission.get_latest_result.id,
                                          extra_mark: { extra_mark: 1 } }, xhr: true
        end
        it { expect(response).to have_http_status(:success) }
        it 'should update the total mark' do
          expect(@old_mark + 1).to eq(submission.get_latest_result.total_mark)
        end
      end
    end
    context 'accessing remove_extra_mark' do
      before :each do
        extra_mark = create(:extra_mark_points, result: submission.get_latest_result)
        submission.get_latest_result.update_total_mark
        @old_mark = submission.get_latest_result.total_mark
        post :remove_extra_mark, params: { assignment_id: assignment.id, submission_id: submission.id,
                                           id: extra_mark.id }, xhr: true
      end
      test_no_flash
      it { expect(response).to have_http_status(:success) }
      it 'should change the total value' do
        submission.get_latest_result.update_total_mark
        expect(@old_mark).not_to eq incomplete_result.total_mark
      end
    end
    context 'accessing update_overall_comment' do
      before :each do
        post :update_overall_comment, params: { assignment_id: assignment.id, submission_id: submission.id,
                                                id: incomplete_result.id,
                                                result: { overall_comment: SAMPLE_COMMENT } }, xhr: true
        incomplete_result.reload
      end
      it { expect(response).to have_http_status(:success) }
      it 'should update the overall comment' do
        expect(incomplete_result.overall_comment).to eq SAMPLE_COMMENT
      end
    end
  end

  ROUTES = { update_mark: :patch,
             edit: :get,
             download: :post,
             get_annotations: :get,
             add_extra_mark: :post,
             download_zip: :get,
             cancel_remark_request: :delete,
             delete_grace_period_deduction: :delete,
             next_grouping: :get,
             remove_extra_mark: :post,
             set_released_to_students: :post,
             update_overall_comment: :post,
             toggle_marking_state: :post,
             update_remark_request: :patch,
             update_positions: :get,
             view_marks: :get,
             add_tag: :post,
             remove_tag: :post,
             run_tests: :post,
             stop_test: :get,
             get_test_runs_instructors: :get,
             get_test_runs_instructors_released: :get }.freeze

  context 'A not logged in user' do
    [:edit,
     :next_grouping,
     :set_released_to_students,
     :toggle_marking_state,
     :update_overall_comment,
     :update_remark_request,
     :cancel_remark_request,
     :download,
     :update_mark,
     :view_marks,
     :add_extra_mark,
     :remove_extra_mark].each { |route_name| test_redirect_no_login(route_name) }
  end

  context 'A student' do
    before(:each) { sign_in student }
    [:edit,
     :next_grouping,
     :set_released_to_students,
     :toggle_marking_state,
     :update_overall_comment,
     :update_mark,
     :add_extra_mark,
     :remove_extra_mark].each { |route_name| test_unauthorized(route_name) }
    include_examples 'download files'
    context 'viewing a file' do
      context 'for a grouping with no submission' do
        before :each do
          allow_any_instance_of(Grouping).to receive(:has_submission?).and_return false
          get :view_marks, params: { assignment_id: assignment.id,
                                     submission_id: submission.id,
                                     id: incomplete_result.id }
        end
        it { expect(response).to render_template('results/student/no_submission') }
        it { expect(response).to have_http_status(:success) }
        test_assigns_not_nil :assignment
        test_assigns_not_nil :grouping
      end
      context 'for a grouping with a submission but no result' do
        before :each do
          allow_any_instance_of(Submission).to receive(:has_result?).and_return false
          get :view_marks, params: { assignment_id: assignment.id,
                                     submission_id: submission.id,
                                     id: incomplete_result.id }
        end
        it { expect(response).to render_template('results/student/no_result') }
        it { expect(response).to have_http_status(:success) }
        test_assigns_not_nil :assignment
        test_assigns_not_nil :grouping
        test_assigns_not_nil :submission
      end
      context 'for a grouping with an unreleased result' do
        before :each do
          allow_any_instance_of(Submission).to receive(:has_result?).and_return true
          allow_any_instance_of(Result).to receive(:released_to_students).and_return false
          get :view_marks, params: { assignment_id: assignment.id,
                                     submission_id: submission.id,
                                     id: incomplete_result.id }
        end
        it { expect(response).to render_template('results/student/no_result') }
        it { expect(response).to have_http_status(:success) }
        test_assigns_not_nil :assignment
        test_assigns_not_nil :grouping
        test_assigns_not_nil :submission
      end
      context 'and the result is available for viewing' do
        before :each do
          allow_any_instance_of(Submission).to receive(:has_result?).and_return true
          allow_any_instance_of(Result).to receive(:released_to_students).and_return true
          get :view_marks, params: { assignment_id: assignment.id,
                                     submission_id: submission.id,
                                     id: complete_result.id }
        end
        it { expect(response).to have_http_status(:success) }
        it { expect(response).to render_template(:view_marks) }
        test_assigns_not_nil :assignment
        test_assigns_not_nil :grouping
        test_assigns_not_nil :submission
        test_assigns_not_nil :result
        test_assigns_not_nil :mark_criteria
        test_assigns_not_nil :annotation_categories
        test_assigns_not_nil :group
        test_assigns_not_nil :files
        test_assigns_not_nil :extra_marks_points
        test_assigns_not_nil :extra_marks_percentage
      end
    end
  end
  context 'An admin' do
    before(:each) { sign_in admin }
    context 'accessing edit' do
      context 'with one grouping with a released result and two others with incomplete results' do
        let :released_result do
          submissions = Array.new(3) do
            create :version_used_submission, grouping: (create :grouping_with_inviter, assignment: assignment)
          end
          create :released_result, submission: submissions.second
        end
        let(:groupings) do
          released_result
          assignment.groupings.order(:id)
        end
        let(:submissions) { groupings.map(&:current_submission_used) }
        let(:results) { submissions.map(&:get_latest_result) }
        xcontext 'and a remark request result' do # TODO: move this to a view spec
          render_views
          before :each do
            released_result.submission.make_remark_result
            released_result.submission.update(remark_request_timestamp: Time.zone.now)
            get :edit, params: { assignment_id: assignment.id, submission_id: released_result.submission.id,
                                 id: released_result.submission.remark_result.id }
          end
          it 'should have an edit form with fields for an overall comment' do
            path = "/en/assignments/#{assignment.id}/submissions/#{released_result.submission.id}/results/#{released_result.id}/update_overall_comment"
            assert_select '.overall-comment textarea'
          end
        end
      end
    end
    context 'accessing set_released_to_students' do
      before :each do
        get :set_released_to_students, params: { assignment_id: assignment.id, submission_id: submission.id,
                                                 id: complete_result.id, value: 'true' }, xhr: true
      end
      it { expect(response).to have_http_status(:success) }
      test_assigns_not_nil :result
    end
    include_examples 'shared ta and admin tests'

    describe '#delete_grace_period_deduction' do
      it 'deletes an existing grace period deduction' do
        expect(grouping.grace_period_deductions.exists?).to be false
        deduction = create(:grace_period_deduction,
                           membership: grouping.accepted_student_memberships.first,
                           deduction: 1)
        expect(grouping.grace_period_deductions.exists?).to be true
        delete :delete_grace_period_deduction,
               params: { assignment_id: assignment.id, submission_id: submission.id,
                         id: complete_result.id, deduction_id: deduction.id }
        expect(grouping.grace_period_deductions.exists?).to be false
      end

      it 'raises a RecordNotFound error when given a grace period deduction that does not exist' do
        expect do
          delete :delete_grace_period_deduction,
                 params: { assignment_id: assignment.id, submission_id: submission.id,
                           id: complete_result.id, deduction_id: 100 }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'raises a RecordNotFound error when given a grace period deduction for a different grouping' do
        student2 = create(:student, grace_credits: 2)
        grouping2 = create(:grouping_with_inviter, assignment: assignment, inviter: student2)
        submission2 = create(:version_used_submission, grouping: grouping2)
        create(:complete_result, submission: submission2)
        deduction = create(:grace_period_deduction,
                           membership: grouping2.accepted_student_memberships.first,
                           deduction: 1)
        expect do
          delete :delete_grace_period_deduction,
                 params: { assignment_id: assignment.id, submission_id: submission.id,
                           id: complete_result.id, deduction_id: deduction.id }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
  context 'A TA' do
    before(:each) { sign_in ta }
    [:set_released_to_students].each { |route_name| test_unauthorized(route_name) }
    context 'accessing edit' do
      before :each do
        get :edit, params: { assignment_id: assignment.id, submission_id: submission.id,
                             id: incomplete_result.id }, xhr: true
      end
      test_no_flash
      it { expect(response).to render_template('edit') }
      it { expect(response).to have_http_status(:success) }
    end
    include_examples 'shared ta and admin tests'
  end
end
