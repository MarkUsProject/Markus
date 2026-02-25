describe ResultsController do
  # TODO: add 'role is from a different course' shared tests to each route test below
  let(:course) { assignment.course }
  let(:assignment) { create(:assignment) }
  let(:student) { create(:student, grace_credits: 2) }
  let(:instructor) { create(:instructor) }
  let(:ta) { create(:ta) }
  let(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: student) }
  let(:submission) { create(:version_used_submission, grouping: grouping) }
  let(:incomplete_result) { submission.current_result }
  let(:complete_result) { create(:complete_result, submission: submission) }
  let(:submission_file) { create(:submission_file, submission: submission) }
  let(:rubric_criterion) { create(:rubric_criterion, assignment: assignment) }
  let(:rubric_mark) { create(:rubric_mark, result: incomplete_result, criterion: rubric_criterion) }
  let(:flexible_criterion) { create(:flexible_criterion, assignment: assignment) }
  let(:flexible_mark) { create(:flexible_mark, result: incomplete_result, criterion: flexible_criterion) }
  let(:from_codeviewer) { nil }

  before do
    stub_const('SAMPLE_ERROR_MESSAGE', 'sample error message'.freeze)
    stub_const('SAMPLE_COMMENT', 'sample comment'.freeze)
    stub_const('ROUTES', {
      update_mark: :patch,
      edit: :get,
      download: :post,
      get_annotations: :get,
      add_extra_mark: :post,
      delete_grace_period_deduction: :delete,
      next_grouping: :get,
      get_filtered_grouping_ids: :get,
      random_incomplete_submission: :get,
      remove_extra_mark: :post,
      revert_to_automatic_deductions: :patch,
      set_released_to_students: :post,
      update_overall_comment: :post,
      toggle_marking_state: :post,
      update_positions: :get,
      view_marks: :get,
      add_tag: :post,
      remove_tag: :post,
      run_tests: :post,
      stop_test: :get,
      get_test_runs_instructors: :get,
      get_test_runs_instructors_released: :get,
      refresh_view_tokens: :put,
      update_view_token_expiry: :put,
      download_view_tokens: :get
    }.freeze)
  end

  after do
    destroy_repos
  end

  def self.test_assigns_not_nil(key)
    it "should assign #{key}" do
      expect(assigns(key)).not_to be_nil
    end
  end

  def self.test_no_flash
    it 'should not display any flash messages' do
      expect(flash).to be_empty
    end
  end

  def self.test_unauthorized(route_name)
    it "should not be authorized to access #{route_name}" do
      method(ROUTES[route_name]).call(route_name, params: { course_id: course.id,
                                                            id: incomplete_result.id,
                                                            assignment_id: assignment.id })
      expect(response).to have_http_status(:forbidden)
    end
  end

  shared_examples 'ta and instructor #next_grouping with filters' do
    let(:grouping1) { create(:grouping_with_inviter_and_submission, is_collected: true) }
    let(:grouping2) do
      create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment, is_collected: true)
    end
    let(:grouping3) do
      create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment, is_collected: true)
    end
    let(:grouping4) { create(:grouping, assignment: grouping1.assignment) }
    let(:groupings) { [grouping1, grouping2, grouping3, grouping4] }

    context 'when annotation text filter is applied' do
      let(:annotation_text) { create(:annotation_text, content: 'aa_') }

      before do
        create(:text_annotation, annotation_text: annotation_text, result: grouping1.current_result)
        create(:text_annotation, annotation_text: annotation_text, result: grouping3.current_result)
      end

      context 'when there are no more filtered submissions in the specified direction' do
        it 'should return a response with next_grouping and next_result set to nil' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping3.id,
                                        id: grouping3.current_result.id,
                                        direction: 1, filterData: { annotationText: 'aa_' } }
          expect(response.parsed_body['next_grouping']).to be_nil
          expect(response.parsed_body['next_result']).to be_nil
        end
      end

      context 'when there is another filtered result after the current one' do
        it 'should return a response with the next filtered group' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { annotationText: 'aa_' } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
          expect(response.parsed_body['next_result']['id']).to eq(grouping3.current_result.id)
        end

        it 'shouldn\'t return the next non-filtered group' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { annotationText: 'aa_' } }
          expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
          expect(response.parsed_body['next_result']['id']).not_to eq(grouping2.current_result.id)
        end
      end

      context 'when annotationText contains special characters (in the context of a like clause)' do
        it 'should sanitize the string and return the next relevant result' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { annotationText: 'aa_' } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
          expect(response.parsed_body['next_result']['id']).to eq(grouping3.current_result.id)
        end
      end

      context 'when we filter by a substring of the desired annotation text' do
        it 'should return the next result containing the substring in one of its annotations' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { annotationText: 'a' } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
          expect(response.parsed_body['next_result']['id']).to eq(grouping3.current_result.id)
        end
      end
    end

    context 'section filter' do
      let(:section) { create(:section) }

      before do
        groupings[0].inviter.update(section: section)
        groupings[1].inviter.update(section: nil)
        groupings[2].inviter.update(section: section)
      end

      context 'when a section has been picked' do
        it 'should return the next group with a larger group name that satisfies the constraints' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { section: 'Section 1' } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
        end

        it 'should not return the next group that doesn\'t satisfy the constraint' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { section: 'Section 1' } }
          expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
        end
      end

      context 'when section is left blank' do
        it 'should return the next grouping without constraints' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { section: '' } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping2.id)
        end
      end
    end

    context 'marking state filter' do
      context 'when remark request is selected' do
        let(:grouping2) do
          result = create(:incomplete_result)
          result.submission.update(submission_version_used: true)
          result.grouping.update(assignment: grouping1.assignment)
          result.grouping
        end
        let(:grouping3) do
          remark_result = create(:remark_result)
          remark_result.submission.update(submission_version_used: true)
          remark_result.grouping.update(assignment: grouping1.assignment)
          remark_result.grouping
        end
        let(:grouping4) do
          remark_result = create(:remark_result)
          remark_result.submission.update(submission_version_used: true)
          remark_result.grouping.update(assignment: grouping1.assignment)
          remark_result.grouping
        end

        before do
          grouping3.current_result.update(marking_state: Result::MARKING_STATES[:complete])
        end

        it 'should respond with the next grouping with a remark requested and who has a marking state of incomplete' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { markingState: 'remark_requested' } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping4.id)
        end

        it 'should not respond with a grouping whose current result is a remark result but is complete' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { markingState: 'remark_requested' } }
          expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping3.id)
        end

        it 'should not respond with a grouping whose current result is not a remark result' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { markingState: 'remark_requested' } }
          expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
        end
      end

      context 'when released is selected' do
        let(:grouping2) do
          result = create(:incomplete_result)
          result.submission.update(submission_version_used: true)
          result.grouping.update(assignment: grouping1.assignment)
          result.grouping
        end
        let(:grouping3) do
          remark_result = create(:complete_result)
          remark_result.submission.update(submission_version_used: true)
          remark_result.grouping.update(assignment: grouping1.assignment)
          remark_result.grouping
        end
        let(:grouping4) do
          remark_result = create(:released_result)
          remark_result.submission.update(submission_version_used: true)
          remark_result.grouping.update(assignment: grouping1.assignment)
          remark_result.grouping
        end

        it 'should respond with the next grouping whose submission has been released' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { markingState: 'released' } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping4.id)
        end
      end

      context 'when complete is selected' do
        let(:grouping2) do
          result = create(:released_result)
          result.submission.update(submission_version_used: true)
          result.grouping.update(assignment: grouping1.assignment)
          result.grouping
        end
        let(:grouping3) do
          remark_result = create(:remark_result, marking_state: Result::MARKING_STATES[:complete])
          remark_result.submission.update(submission_version_used: true)
          remark_result.grouping.update(assignment: grouping1.assignment)
          remark_result.grouping
        end

        it 'responds with the next grouping whose result is complete regardless of remark request status' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { markingState: 'complete' } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
        end

        it 'should not respond with a released result regardless of the result\'s marking status' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { markingState: 'complete' } }
          expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
        end
      end

      context 'when in progress is selected' do
        let(:grouping2) do
          result = create(:remark_result)
          result.submission.update(submission_version_used: true)
          result.grouping.update(assignment: grouping1.assignment)
          result.grouping
        end
        let(:grouping3) do
          remark_result = create(:released_result)
          remark_result.submission.update(submission_version_used: true)
          remark_result.grouping.update(assignment: grouping1.assignment)
          remark_result.grouping
        end
        let(:grouping4) do
          remark_result = create(:incomplete_result)
          remark_result.submission.update(submission_version_used: true)
          remark_result.grouping.update(assignment: grouping1.assignment)
          remark_result.grouping
        end

        it 'should respond with the next grouping whose result is incomplete' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { markingState: 'in_progress' } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping4.id)
        end

        it 'should not respond with a released or remark result' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { markingState: 'in_progress' } }
          expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
          expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping3.id)
        end
      end

      context 'when markingState is left blank' do
        let(:grouping2) do
          result = create(:incomplete_result)
          result.submission.update(submission_version_used: true)
          result.grouping.update(assignment: grouping1.assignment)
          result.grouping
        end
        let(:grouping3) do
          remark_result = create(:remark_result)
          remark_result.submission.update(submission_version_used: true)
          remark_result.grouping.update(assignment: grouping1.assignment)
          remark_result.grouping
        end
        let(:grouping4) do
          remark_result = create(:remark_result)
          remark_result.submission.update(submission_version_used: true)
          remark_result.grouping.update(assignment: grouping1.assignment)
          remark_result.grouping
        end

        it 'should return the next group regardless of marking state' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { markingState: '' } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping2.id)
        end
      end
    end

    context 'when filtering by tags' do
      let(:tag1) { create(:tag, groupings: [grouping1, grouping3], name: 'tag1') }
      let(:tag2) { create(:tag, groupings: [grouping2, grouping3], name: 'tag2') }

      context 'when a tag has been picked' do
        it 'should return the next group with a larger group name that satisfies the constraints' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { tags: [tag1.name] } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
        end

        it 'should not return the next group that doesn\'t satisfy the constraint' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { tags: [tag1.name] } }
          expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
        end
      end

      context 'when multiple tags have been picked' do
        it 'should return the next group with a larger group name that has at least one of the tags' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { tags: [tag1.name, tag2.name] } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping2.id)
        end
      end

      context 'when no tag has been picked' do
        it 'should return the next grouping without constraints' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { tags: [] } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping2.id)
        end
      end
    end

    context 'when filtering by total mark' do
      let(:grouping4) do
        create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment, is_collected: true)
      end
      let(:assignment) { grouping1.assignment }
      let(:criterion) { create(:flexible_criterion, assignment: assignment, max_mark: 10) }

      before do
        create(:flexible_mark, criterion: criterion, result: grouping2.current_result, mark: 6)
        create(:flexible_mark, criterion: criterion, result: grouping3.current_result, mark: 10)
        create(:flexible_mark, criterion: criterion, result: grouping4.current_result, mark: 5)
      end

      context 'when no range is provided' do
        it 'should return the next grouping without constraints' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { totalMarkRange: {} } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping2.id)
        end
      end

      context 'when minimum value is provided' do
        it 'should return the next group with a larger group name that satisfies the constraints' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { totalMarkRange: { min: 7.00 } } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
        end

        it 'should not return the next group that doesn\'t satisfy the constraint' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { totalMarkRange: { min: 7.00 } } }
          expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
        end
      end

      context 'when maximum value is provided' do
        it 'should return the next group with a larger group name that satisfies the constraints' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { totalMarkRange: { max: 5.00 } } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping4.id)
        end

        it 'should not return the next group that doesn\'t satisfy the constraint' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { totalMarkRange: { max: 5.00 } } }
          expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
        end
      end

      context 'when minimum and maximum values are provided' do
        it 'should return the next group with a larger group name that satisfies the constraints' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { totalMarkRange: { min: 4.00, max: 5.00 } } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping4.id)
        end

        it 'should not return the next group that doesn\'t satisfy the constraint' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { totalMarkRange: { min: 4.00, max: 5.00 } } }
          expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
        end
      end
    end

    context 'when filtering by total extra mark' do
      let(:grouping4) do
        create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment, is_collected: true)
      end
      let(:assignment) { grouping1.assignment }

      before do
        create(:extra_mark_points, result: grouping2.current_result, extra_mark: 6)
        create(:extra_mark_points, result: grouping3.current_result, extra_mark: 10)
        create(:extra_mark_points, result: grouping4.current_result, extra_mark: 5)
      end

      context 'when no range is provided' do
        it 'should return the next grouping without constraints' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { totalExtraMarkRange: {} } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping2.id)
        end
      end

      context 'when minimum value is provided' do
        it 'should return the next group with a larger group name that satisfies the constraints' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { totalExtraMarkRange: { min: 7.00 } } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
        end

        it 'should not return the next group that doesn\'t satisfy the constraint' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { totalExtraMarkRange: { min: 7.00 } } }
          expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
        end
      end

      context 'when maximum value is provided' do
        it 'should return the next group with a larger group name that satisfies the constraints' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { totalExtraMarkRange: { max: 5.00 } } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping4.id)
        end

        it 'should not return the next group that doesn\'t satisfy the constraint' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { totalExtraMarkRange: { max: 5.00 } } }
          expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
        end
      end

      context 'when minimum and maximum values are provided' do
        it 'should return the next group with a larger group name that satisfies the constraints' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { totalExtraMarkRange: { min: 4.00, max: 5.00 } } }
          expect(response.parsed_body['next_grouping']['id']).to eq(grouping4.id)
        end

        it 'should not return the next group that doesn\'t satisfy the constraint' do
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                        id: grouping1.current_result.id,
                                        direction: 1, filterData: { totalExtraMarkRange: { min: 4.00, max: 5.00 } } }
          expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
        end
      end
    end

    context 'when filtering by criteria' do
      let(:assignment) { grouping1.assignment }
      let!(:criterion) { create(:flexible_criterion, assignment: assignment, max_mark: 10) }
      let(:grouping2_mark) { 1 }

      before do
        create(:flexible_mark, criterion: criterion, result: grouping1.current_result, mark: 1)
        create(:flexible_mark, criterion: criterion, result: grouping2.current_result, mark: grouping2_mark)
        create(:flexible_mark, criterion: criterion, result: grouping3.current_result, mark: 3)
      end

      context 'when a single criteria is specified' do
        context 'when only min is specified' do
          let(:grouping2_mark) { 0 }

          it 'should not select the next grouping whose result does not satisfy the conditions' do
            get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                          id: grouping1.current_result.id,
                                          direction: 1, filterData: { criteria: { 'Flexible criterion 1': {
                                            min: 1
                                          } } } }
            expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
          end

          it 'should select the next grouping whose result satisfies the conditions' do
            get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                          id: grouping1.current_result.id,
                                          direction: 1, filterData: { criteria: { 'Flexible criterion 1': {
                                            min: 1
                                          } } } }
            expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
          end
        end

        context 'when only max is specified' do
          let(:grouping2_mark) { 8 }

          it 'should not select the next grouping whose result does not satisfy the conditions' do
            get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                          id: grouping1.current_result.id,
                                          direction: 1, filterData: { criteria: { 'Flexible criterion 1': {
                                            max: 3
                                          } } } }
            expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
          end

          it 'should select the next grouping whose result satisfies the conditions' do
            get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                          id: grouping1.current_result.id,
                                          direction: 1, filterData: { criteria: { 'Flexible criterion 1': {
                                            max: 3
                                          } } } }
            expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
          end
        end

        context 'when both max and min are specified' do
          let(:grouping2_mark) { 8 }

          it 'should not select the next grouping whose result does not satisfy the conditions' do
            get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                          id: grouping1.current_result.id,
                                          direction: 1, filterData: { criteria: { 'Flexible criterion 1': {
                                            min: 1, max: 3
                                          } } } }
            expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
          end

          it 'should select the next grouping whose result satisfies the conditions' do
            get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                          id: grouping1.current_result.id,
                                          direction: 1, filterData: { criteria: { 'Flexible criterion 1': {
                                            min: 1, max: 3
                                          } } } }
            expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
          end
        end

        context 'when min and max are not specified' do
          it 'should get the next grouping without any constraints applied' do
            get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                          id: grouping1.current_result.id,
                                          direction: 1, filterData: { criteria: { 'Flexible criterion 1': {} } } }
            expect(response.parsed_body['next_grouping']['id']).to eq(grouping2.id)
          end
        end

        context 'when min and max are empty strings' do
          it 'should get the next grouping without any constraints applied' do
            get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                          id: grouping1.current_result.id,
                                          direction: 1, filterData: { criteria: { 'Flexible criterion 1': {
                                            min: '', max: ''
                                          } } } }
            expect(response.parsed_body['next_grouping']['id']).to eq(grouping2.id)
          end
        end
      end

      context 'when multiple criteria are specified' do
        let!(:criterion2) { create(:flexible_criterion, assignment: assignment, max_mark: 10) }

        before do
          create(:flexible_mark, criterion: criterion2, result: grouping1.current_result, mark: 1)
          create(:flexible_mark, criterion: criterion2, result: grouping3.current_result, mark: 3)
        end

        context 'when both max and min are specified' do
          it 'does not select the next grouping whose result does not have a mark for the second criterion' do
            get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                          id: grouping1.current_result.id,
                                          direction: 1,
                                          filterData: { criteria: { 'Flexible criterion 1': { min: 1, max: 3 },
                                                                    'Flexible criterion 2': { min: 1, max: 3 } } } }
            expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
          end

          it 'selects the next grouping whose result satisfies the conditions' do
            create(:flexible_mark, criterion: criterion2, result: grouping2.current_result, mark: 5)
            get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                          id: grouping1.current_result.id,
                                          direction: 1,
                                          filterData: { criteria: { 'Flexible criterion 1': { min: 1, max: 3 },
                                                                    'Flexible criterion 2': { min: 1, max: 3 } } } }
            expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
          end
        end
      end
    end
  end

  shared_examples 'instructor and ta #next_grouping with different orderings' do
    context 'with 3 groupings' do
      let(:grouping1) { create(:grouping_with_inviter_and_submission, is_collected: true) }
      let(:grouping2) do
        create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment, is_collected: true)
      end
      let(:grouping3) do
        create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment, is_collected: true)
      end
      let(:groupings) { [grouping1, grouping2, grouping3] }

      context 'order by group name' do
        context 'Descending Order' do
          context 'direction = 1' do
            it 'should return the next grouping in descending order of group name' do
              get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                            id: grouping2.current_result.id,
                                            direction: 1, filterData: { ascending: 'false', orderBy: 'group_name' } }
              expect(response.parsed_body['next_grouping']['id']).to eq(grouping1.id)
            end
          end

          context 'direction = -1' do
            it 'should return the previous grouping in descending order of group name' do
              get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                            id: grouping2.current_result.id,
                                            direction: -1, filterData: { ascending: 'false', orderBy: 'group_name' } }
              expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
            end
          end
        end
      end

      context 'order by submission date' do
        context 'Ascending Order' do
          context 'when direction = 1' do
            context 'when the ordered submission has a different submission date from the current one' do
              it 'should return the grouping with the next latest submission date' do
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: 1, filterData:
                                                { ascending: 'true', orderBy: 'submission_date' } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
              end
            end

            context 'when the next ordered submission shares has the same submission date as the current one' do
              let(:grouping1) { create(:grouping_with_inviter_and_submission, is_collected: true) }
              let(:grouping2) do
                create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment, is_collected: true)
              end
              let(:grouping3) do
                create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment, is_collected: true)
              end

              before do
                3.times do |i|
                  groupings[i].current_submission_used.update(revision_timestamp: Date.current)
                end
              end

              it 'should return the grouping with the next largest group name with the same submission date' do
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: 1, filterData:
                                                { ascending: 'true', orderBy: 'submission_date' } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
              end
            end
          end

          context 'direction = -1' do
            context 'when the previous ordered submission has a different submission date from the current one' do
              it 'should return the grouping with the next earliest submission date' do
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: -1, filterData:
                                                { ascending: 'true', orderBy: 'submission_date' } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping1.id)
              end
            end

            context 'when the previous ordered submission shares has the same submission date as the current one' do
              let(:grouping1) { create(:grouping_with_inviter_and_submission, is_collected: true) }
              let(:grouping2) do
                create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment, is_collected: true)
              end
              let(:grouping3) do
                create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment, is_collected: true)
              end

              before do
                3.times do |i|
                  groupings[i].current_submission_used.update(revision_timestamp: Date.current)
                end
              end

              it 'should return the grouping with the next smallest group name with the same submission date' do
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: -1, filterData:
                                                { ascending: 'true', orderBy: 'submission_date' } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping1.id)
              end
            end
          end
        end

        context 'Descending Order' do
          context 'direction = 1' do
            context 'when the next ordered submission has a different submission date from the current one' do
              it 'should return the grouping with the next earliest submission date' do
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: 1, filterData:
                                                { ascending: 'false', orderBy: 'submission_date' } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping1.id)
              end
            end

            context 'when the next ordered submission shares has the same submission date as the current one' do
              let(:grouping1) { create(:grouping_with_inviter_and_submission, is_collected: true) }
              let(:grouping2) do
                create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment, is_collected: true)
              end
              let(:grouping3) do
                create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment, is_collected: true)
              end

              before do
                3.times do |i|
                  groupings[i].current_submission_used.update(revision_timestamp: Date.current)
                end
              end

              it 'should return the grouping with the next smallest group name with the same submission date' do
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: 1, filterData:
                                              { ascending: 'false', orderBy: 'submission_date' } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping1.id)
              end
            end
          end

          context 'direction = -1' do
            context 'when the previous ordered submission has a different submission date from the current one' do
              it 'should return the grouping with the next latest submission date' do
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: -1, filterData: {
                                                ascending: 'false', orderBy: 'submission_date'
                                              } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
              end
            end

            context 'when the previous ordered submission shares has the same submission date as the current one' do
              let(:grouping1) { create(:grouping_with_inviter_and_submission, is_collected: true) }
              let(:grouping2) do
                create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment, is_collected: true)
              end
              let(:grouping3) do
                create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment, is_collected: true)
              end

              before do
                3.times do |i|
                  groupings[i].current_submission_used.update(revision_timestamp: Date.current)
                end
              end

              it 'should return the grouping with the next largest group name with the same submission date' do
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: -1, filterData: {
                                                ascending: 'false', orderBy: 'submission_date'
                                              } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
              end
            end
          end
        end
      end

      context 'order by total mark' do
        let(:assignment) { grouping1.assignment }
        let(:criterion) { create(:flexible_criterion, assignment: assignment, max_mark: 10) }
        let!(:mark1) do
          create(:flexible_mark, criterion: criterion, result: grouping1.current_result, mark: 1)
        end
        let!(:mark2) do
          create(:flexible_mark, criterion: criterion, result: grouping2.current_result, mark: 2)
        end
        let!(:mark3) do
          create(:flexible_mark, criterion: criterion, result: grouping3.current_result, mark: 3)
        end

        context 'Ascending Order' do
          context 'when direction = 1' do
            context 'when the next ordered submission has a different total mark from the current one' do
              it 'should return the next grouping with a larger total mark' do
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: 1, filterData: { ascending: 'true', orderBy: 'total_mark' } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
              end
            end

            context 'when the next ordered submission shares the same total mark as the current one' do
              it 'should return the grouping with the next largest group name with the same total mark' do
                mark1.update(mark: 1)
                mark2.update(mark: 1)
                mark3.update(mark: 1)
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: 1, filterData: { ascending: 'true', orderBy: 'total_mark' } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
              end
            end
          end

          context 'direction = -1' do
            context 'when the previous ordered submission has a different total mark from the current one' do
              it 'should return the grouping with the next smallest group name with the same total mark' do
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: -1, filterData: { ascending: 'true', orderBy: 'total_mark' } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping1.id)
              end
            end

            context 'when the previous ordered submission shares has the same total mark as the current one' do
              it 'should return the grouping with the next smallest group name with the same total mark' do
                mark1.update(mark: 1)
                mark2.update(mark: 1)
                mark3.update(mark: 1)
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: -1, filterData: { ascending: 'true', orderBy: 'total_mark' } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping1.id)
              end
            end
          end
        end

        context 'Descending Order' do
          context 'direction = 1' do
            context 'when the next ordered submission has a different total mark from the current one' do
              it 'should return the grouping with the next smallest total mark' do
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: 1, filterData: { ascending: 'false', orderBy: 'total_mark' } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping1.id)
              end
            end

            context 'when the next ordered submission shares has the same total mark as the current one' do
              it 'should return the grouping with the next smallest group name with the same total mark' do
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: 1, filterData: { ascending: 'false', orderBy: 'total_mark' } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping1.id)
              end
            end
          end

          context 'direction = -1' do
            context 'when the previous ordered submission has a different total mark from the current one' do
              it 'should return the grouping with the next largest total mark' do
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: -1, filterData: {
                                                ascending: 'false', orderBy: 'total_mark'
                                              } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
              end
            end

            context 'when the previous ordered submission shares has the same total mark as the current one' do
              it 'should return the grouping with the next largest group name with the same total mark' do
                mark1.update(mark: 1)
                mark2.update(mark: 1)
                mark3.update(mark: 1)
                get :next_grouping, params: { course_id: course.id, grouping_id: grouping2.id,
                                              id: grouping2.current_result.id,
                                              direction: -1, filterData: {
                                                ascending: 'false', orderBy: 'total_mark'
                                              } }
                expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
              end
            end
          end
        end
      end
    end
  end

  shared_examples 'shared ta and instructor tests' do
    context 'accessing next_grouping' do
      it 'should receive 200 when current grouping has a submission' do
        allow_any_instance_of(Grouping).to receive(:has_submission).and_return true
        get :next_grouping, params: { course_id: course.id, grouping_id: grouping.id, id: incomplete_result.id }
        expect(response).to have_http_status(:ok)
      end

      it 'should receive 200 when current grouping does not have a submission' do
        allow_any_instance_of(Grouping).to receive(:has_submission).and_return false
        get :next_grouping, params: { course_id: course.id, grouping_id: grouping.id, id: incomplete_result.id }
        expect(response).to have_http_status(:ok)
      end

      it 'should receive a JSON object of the next grouping when next grouping has a submission' do
        a2 = create(:assignment_with_criteria_and_results)
        a2.groupings.each do |group|
          group.tas.push(ta)
          group.save
        end
        a2.save
        get :next_grouping, params: { course_id: course.id,
                                      grouping_id: a2.groupings.first.id,
                                      id: a2.submissions.first.current_result.id }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('next_result', 'next_grouping')
      end
    end

    context 'accessing toggle_marking_state' do
      context 'with a complete result' do
        before do
          post :toggle_marking_state, params: { course_id: course.id, id: complete_result.id }, xhr: true
        end

        it { expect(response).to have_http_status(:success) }
        # TODO: test that the grade distribution is refreshed
      end
    end

    context 'accessing update_mark' do
      it 'should report an updated mark' do
        patch :update_mark, params: { course_id: course.id,
                                      id: incomplete_result.id,
                                      criterion_id: rubric_mark.criterion_id,
                                      mark: 1 }, xhr: true
        expect(response.parsed_body['num_marked']).to eq 0
        expect(rubric_mark.reload.override).to be true
      end

      context 'setting override when annotations linked to criteria exist' do
        let(:assignment) { create(:assignment_with_deductive_annotations) }
        let(:result) { assignment.groupings.first.current_result }
        let(:submission) { result.submission }
        let(:mark) { assignment.groupings.first.current_result.marks.first }

        before { create(:ta_membership, role: ta, grouping: assignment.groupings.first) }

        it 'sets override to true for mark if input value is not null' do
          patch :update_mark, params: { course_id: course.id,
                                        id: result.id, criterion_id: mark.criterion_id,
                                        mark: 3.0 }, xhr: true
          expect(mark.reload.override).to be true
        end

        it 'sets override to true for mark if input value null and deductive annotations exist' do
          patch :update_mark, params: { course_id: course.id,
                                        id: result.id, criterion_id: mark.criterion_id,
                                        mark: '' }, xhr: true
          expect(mark.reload.override).to be true
        end

        it 'sets override to false for mark if input value null and only annotations with 0 value deduction exist' do
          assignment.annotation_categories.where.not(flexible_criterion: nil).first
                    .annotation_texts.first.update!(deduction: 0)
          patch :update_mark, params: { course_id: course.id,
                                        id: result.id, criterion_id: mark.criterion_id,
                                        mark: '' }, xhr: true
          expect(mark.reload.override).to be false
        end
      end

      it 'returns correct json fields when updating a mark' do
        patch :update_mark, params: { course_id: course.id,
                                      id: incomplete_result.id, criterion_id: rubric_mark.criterion_id,
                                      mark: '1', format: :json }, xhr: true
        expected_keys = %w[total subtotal mark_override num_marked mark]
        expect(response.parsed_body.keys.sort!).to eq(expected_keys.sort!)
      end

      it 'sets override to false for mark if input value null and no deductive annotations exist' do
        patch :update_mark, params: { course_id: course.id,
                                      id: incomplete_result.id, criterion_id: rubric_mark.criterion_id,
                                      mark: '', format: :json }, xhr: true
        expect(response.parsed_body['mark_override']).to be false
      end

      it { expect(response).to have_http_status(:redirect) }

      context 'but cannot save the mark' do
        before do
          allow_any_instance_of(Mark).to receive(:save).and_return false
          allow_any_instance_of(ActiveModel::Errors).to receive(:full_messages).and_return [SAMPLE_ERROR_MESSAGE]
          patch :update_mark, params: { course_id: course.id,
                                        id: incomplete_result.id, criterion_id: rubric_mark.criterion_id,
                                        mark: 1 }, xhr: true
        end

        it { expect(response).to have_http_status(:bad_request) }

        it 'should report the correct error message' do
          expect(response.body).to match SAMPLE_ERROR_MESSAGE
        end
      end

      context 'when duplicate marks exist' do
        # NOTE: this should not occur but it does happen because of concurrent requests and the fact that
        #       the find_or_create_by method is not atomic and neither are database writes
        let(:mark2) { build(:mark, result: flexible_mark.result, criterion: flexible_mark.criterion) }

        before do
          mark2.save(validate: false)
          patch :update_mark, params: { course_id: course.id,
                                        id: incomplete_result.id,
                                        criterion_id: flexible_mark.criterion_id,
                                        mark: 1 }, xhr: true
        end

        it 'should update the mark' do
          expect(flexible_mark.reload.mark).to eq 1
        end

        it 'should result in a valid mark' do
          expect(flexible_mark.reload).to be_valid
        end

        it 'should destroy the other duplicate mark' do
          expect { mark2.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'accessing view_mark' do
      before do
        get :view_marks, params: { course_id: course.id,
                                   id: incomplete_result.id }, xhr: true
      end

      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'accessing add_extra_mark' do
      context 'and user can access the action' do
        context 'but cannot save the mark' do
          before do
            allow_any_instance_of(ExtraMark).to receive(:save).and_return false
            @old_mark = submission.get_latest_result.get_total_mark
            post :add_extra_mark, params: { course_id: course.id,
                                            id: submission.get_latest_result.id,
                                            extra_mark: { extra_mark: 1 } }, xhr: true
          end

          it { expect(response).to have_http_status(:bad_request) }

          it 'should not update the total mark' do
            expect(@old_mark).to eq(submission.get_latest_result.get_total_mark)
          end
        end

        context 'and can save the mark' do
          before do
            allow_any_instance_of(ExtraMark).to receive(:save).and_call_original
            @old_mark = submission.get_latest_result.get_total_mark
            post :add_extra_mark, params: { course_id: course.id,
                                            id: submission.get_latest_result.id,
                                            extra_mark: { extra_mark: 1 } }, xhr: true
          end

          it { expect(response).to have_http_status(:success) }

          it 'should update the total mark' do
            expect(@old_mark + 1).to eq(submission.get_latest_result.get_total_mark)
          end
        end
      end
    end

    context 'accessing remove_extra_mark' do
      before do
        extra_mark = create(:extra_mark_points, result: submission.get_latest_result)
        @old_mark = submission.get_latest_result.get_total_mark
        delete :remove_extra_mark, params: { course_id: course.id,
                                             id: submission.get_latest_result.id,
                                             extra_mark_id: extra_mark.id }, xhr: true
      end

      test_no_flash
      it { expect(response).to have_http_status(:success) }

      it 'should change the total value' do
        expect(@old_mark).not_to eq incomplete_result.get_total_mark
      end
    end

    context 'accessing an assignment with deductive annotations' do
      let(:assignment) { create(:assignment_with_deductive_annotations) }
      let(:mark) { assignment.groupings.first.current_result.marks.first }

      before { create(:ta_membership, role: ta, grouping: assignment.groupings.first) }

      it 'returns annotation data with criteria information' do
        post :get_annotations, params: { course_id: course.id,
                                         id: assignment.groupings.first.current_result,
                                         format: :json }, xhr: true

        criterion = assignment.criteria.where(type: 'FlexibleCriterion').first
        expect(response.parsed_body.first['criterion_name']).to eq criterion.name
        expect(response.parsed_body.first['criterion_id']).to eq criterion.id
        expect(response.parsed_body.first['deduction']).to eq 1.0
      end

      it 'returns annotation_category data with deductive information' do
        category = assignment.annotation_categories.where.not(flexible_criterion: nil).first
        post :show, params: { course_id: course.id,
                              id: assignment.groupings.first.current_result,
                              format: :json }, xhr: true

        expect(response.parsed_body['annotation_categories'].first['annotation_category_name'])
          .to eq "#{category.annotation_category_name} [#{category.flexible_criterion.name}]"
        expect(response.parsed_body['annotation_categories'].first['texts'].first['deduction']).to eq 1.0
        expect(response.parsed_body['annotation_categories']
                       .first['flexible_criterion_id']).to eq category.flexible_criterion.id
      end

      it 'reverts a mark to a value calculated from automatic deductions correctly' do
        mark.update!(override: true, mark: 3.0)
        patch :revert_to_automatic_deductions, params: {
          course_id: course.id,
          id: assignment.groupings.first.current_result,
          criterion_id: mark.criterion_id,
          format: :json
        }, xhr: true

        mark.reload
        expect(mark.mark).to eq 2.0
        expect(mark.override).to be false
      end

      it 'returns correct information when reverting a mark to a value calculated from automatic deductions' do
        mark.update!(override: true, mark: 3.0)
        patch :revert_to_automatic_deductions, params: {
          course_id: course.id,
          id: assignment.groupings.first.current_result,
          criterion_id: mark.criterion_id,
          format: :json
        }, xhr: true

        expected_keys = %w[total subtotal num_marked mark]
        expect(response.parsed_body.keys.sort!).to eq(expected_keys.sort!)
      end
    end

    describe '#add_tag' do
      it 'adds a tag to a grouping' do
        tag = create(:tag)
        post :add_tag,
             params: { course_id: course.id, id: complete_result.id, tag_id: tag.id }
        expect(complete_result.submission.grouping.tags.to_a).to eq [tag]
      end
    end

    describe '#remove_tag' do
      it 'removes a tag from a grouping' do
        tag = create(:tag)
        submission.grouping.tags << tag
        post :remove_tag,
             params: { course_id: course.id, id: complete_result.id, tag_id: tag.id }
        expect(complete_result.submission.grouping.tags.size).to eq 0
      end
    end

    describe '#get_test_runs_instructors' do
      it 'should be authorized to access the action' do
        get :get_test_runs_instructors, params: { course_id: course.id,
                                                  id: incomplete_result.id,
                                                  assignment_id: assignment.id }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'accessing edit' do
      before do
        get :edit, params: { course_id: course.id, id: incomplete_result.id }, xhr: true
      end

      test_no_flash
      it { expect(response).to render_template('edit') }
      it { expect(response).to have_http_status(:success) }
    end

    describe '#update_overall_comment' do
      before do
        post :update_overall_comment, params: { course_id: course.id,
                                                id: incomplete_result.id,
                                                result: { overall_comment: SAMPLE_COMMENT } }, xhr: true
        incomplete_result.reload
      end

      it { expect(response).to have_http_status(:success) }

      it 'should update the overall comment' do
        expect(incomplete_result.overall_comment).to eq SAMPLE_COMMENT
      end
    end

    describe '#toggle_marking_state' do
      it {
        post :toggle_marking_state, params: { course_id: course.id, id: complete_result.id }, xhr: true
        expect(response).to have_http_status(:success)
      }
    end
  end

  shared_examples 'showing json data' do |is_student|
    subject do
      allow_any_instance_of(Result).to receive(:released_to_students?).and_return true
      get :show, params: { course_id: complete_result.course.id,
                           id: complete_result.id,
                           format: :json }
    end

    let(:student2) do
      partner = create(:student, grace_credits: 2)
      create(:accepted_student_membership, role: partner, grouping: grouping)
      partner
    end

    context 'user has access to view the result' do
      it 'contains important basic data' do
        subject
        expect(response).to have_http_status(:ok)
        data = response.parsed_body
        received_data = {
          instructor_run: data['instructor_run'],
          is_reviewer: data['is_reviewer'],
          student_view: data['student_view'],
          can_run_tests: data['can_run_tests'],
          submission_time: data['submission_time']
        }
        expected_data = {
          instructor_run: true,
          is_reviewer: false,
          student_view: is_student,
          can_run_tests: false,
          submission_time: I18n.l(submission.revision_timestamp.in_time_zone)
        }
        expect(received_data).to eq(expected_data)
      end

      it 'has submission file data' do
        submission_file
        subject
        data = response.parsed_body
        file_data = submission.submission_files.order(:path, :filename).pluck_to_hash(:id, :filename, :path)
        file_data.reject! { |f| Repository.get_class.internal_file_names.include? f[:filename] }

        # checks the correct value of keys that are present in both `file_data` and `data`
        file_data[0].each do |key, value|
          data[:submission_files].each do |submission_file_data|
            expect(submission_file_data).to have_key(key)
            expect(submission_file_data[key]).to eq value
          end
        end

        expect(data[:submission_files]).to all(include(:id, :filename, :path, :type))
      end

      it 'has no annotation categories data' do
        subject
        data = response.parsed_body
        expected_data = is_student ? be_nil : eq([])
        expect(data['annotation_categories']).to expected_data
      end

      it 'has no grace token deduction data' do
        subject
        data = response.parsed_body
        expect(data['grace_token_deductions']).to eq([])
      end

      context 'with grace token deductions' do
        let!(:grace_period_deduction1) do
          create(:grace_period_deduction, membership: grouping.memberships.find_by(role: student))
        end
        let!(:grace_period_deduction2) do
          create(:grace_period_deduction, membership: grouping.memberships.find_by(role: student2))
        end

        it 'sends grace token deduction data' do
          subject
          data = response.parsed_body
          expected_deduction_data = [
            {
              id: grace_period_deduction1.id,
              deduction: grace_period_deduction1.deduction,
              'users.user_name': student.user_name,
              'users.display_name': student.display_name
            }.stringify_keys
          ]
          unless is_student
            expected_deduction_data << {
              id: grace_period_deduction2.id,
              deduction: grace_period_deduction2.deduction,
              'users.user_name': student2.user_name,
              'users.display_name': student2.display_name
            }.stringify_keys
          end
          expect(data['grace_token_deductions']).to eq(expected_deduction_data)
        end
      end

      context 'when there is no submission' do
        before do
          submission.update!(
            revision_identifier: nil,
            revision_timestamp: nil
          )
        end

        it 'sends a submission_time of null' do
          subject
          data = response.parsed_body

          expect(data['submission_time']).to be_nil
        end
      end
    end
  end

  context 'A student' do
    before { sign_in student }

    [:edit,
     :next_grouping,
     :get_filtered_grouping_ids,
     :random_incomplete_submission,
     :set_released_to_students,
     :toggle_marking_state,
     :update_overall_comment,
     :update_mark,
     :add_extra_mark,
     :remove_extra_mark,
     :refresh_view_tokens,
     :update_view_token_expiry,
     :download_view_tokens].each { |route_name| test_unauthorized(route_name) }
    it_behaves_like 'showing json data', true
    describe '#view_token_check' do
      subject { get :view_token_check, params: params }

      let(:role) { create(:student) }
      let(:grouping) { create(:grouping_with_inviter_and_submission, inviter: student) }
      let(:record) { grouping.current_result }
      let(:assignment) { record.grouping.assignment }
      let(:view_token) { nil }
      let(:base_params) { { course_id: record.course.id, id: record.id } }
      let(:params) { view_token ? { **base_params, view_token: view_token } : base_params }

      context 'assignment.release_with_urls is false' do
        before { assignment.update! release_with_urls: false }

        it { is_expected.to have_http_status(:forbidden) }

        it 'should not flash an error message' do
          subject
          expect(flash.now[:error]).to be_blank
        end
      end

      context 'assignment.release_with_urls is true' do
        before { assignment.update! release_with_urls: true }

        context 'the view token does not match the record token' do
          let(:view_token) { "#{record.view_token}abc123" }

          it { is_expected.to have_http_status(:unauthorized) }

          it 'should flash an error message' do
            subject
            expect(flash.now[:error]).not_to be_blank
          end
        end

        context 'the view token matches the record token' do
          let(:view_token) { record.view_token }

          context 'the token does not have an expiry set' do
            it { is_expected.to have_http_status(:success) }

            it 'should not flash an error message' do
              subject
              expect(flash.now[:error]).to be_blank
            end
          end

          context 'the record has a token expiry set in the future' do
            before { record.update! view_token_expiry: 1.hour.from_now }

            it { is_expected.to have_http_status(:success) }

            it 'should not flash an error message' do
              subject
              expect(flash.now[:error]).to be_blank
            end
          end

          context 'the record has a token expiry set in the past' do
            before { record.update! view_token_expiry: 1.hour.ago }

            it { is_expected.to have_http_status(:forbidden) }

            it 'should not flash an error message' do
              subject
              expect(flash.now[:error]).to be_blank
            end
          end
        end
      end
    end

    context 'viewing a file' do
      context 'for a grouping with no submission' do
        before do
          allow_any_instance_of(Grouping).to receive(:has_submission?).and_return false
          get :view_marks, params: { course_id: course.id,
                                     id: incomplete_result.id }
        end

        it { expect(response).to render_template('results/student/no_submission') }
        it { expect(response).to have_http_status(:success) }

        test_assigns_not_nil :assignment
        test_assigns_not_nil :grouping
      end

      context 'for a grouping with a submission but no result' do
        before do
          allow_any_instance_of(Submission).to receive(:has_result?).and_return false
          get :view_marks, params: { course_id: course.id,
                                     id: incomplete_result.id }
        end

        it { expect(response).to render_template('results/student/no_result') }
        it { expect(response).to have_http_status(:success) }

        test_assigns_not_nil :assignment
        test_assigns_not_nil :grouping
        test_assigns_not_nil :submission
      end

      context 'for a grouping with an unreleased result' do
        before do
          allow_any_instance_of(Submission).to receive(:has_result?).and_return true
          allow_any_instance_of(Result).to receive(:released_to_students).and_return false
          get :view_marks, params: { course_id: course.id,
                                     id: incomplete_result.id }
        end

        it { expect(response).to render_template('results/student/no_result') }
        it { expect(response).to have_http_status(:success) }

        test_assigns_not_nil :assignment
        test_assigns_not_nil :grouping
        test_assigns_not_nil :submission
      end

      context 'and the result is available for viewing' do
        subject { get :view_marks, params: { course_id: course.id, id: complete_result.id } }

        before do
          allow_any_instance_of(Submission).to receive(:has_result?).and_return true
          allow_any_instance_of(Result).to receive(:released_to_students).and_return true
        end

        context 'assignment.release_with_urls is false' do
          before { subject }

          it { expect(response).to have_http_status(:success) }
          it { expect(response).to render_template(:view_marks) }

          test_assigns_not_nil :assignment
          test_assigns_not_nil :grouping
          test_assigns_not_nil :submission
          test_assigns_not_nil :result
          test_assigns_not_nil :annotation_categories
          test_assigns_not_nil :group
          test_assigns_not_nil :files
        end

        context 'assignment.release_with_urls is true' do
          subject do
            get :view_marks,
                params: params,
                session: session
          end

          before { assignment.update! release_with_urls: true }

          let(:view_token) { complete_result.view_token }
          let(:session) { {} }
          let(:params) { { course_id: course.id, id: complete_result.id, view_token: view_token } }

          context 'view token has expired' do
            before { allow_any_instance_of(Result).to receive(:view_token_expired?).and_return(true) }

            it 'should be forbidden when the tokens match' do
              subject
              expect(response).to have_http_status(:forbidden)
            end
          end

          context 'view token has not expired' do
            before { allow_any_instance_of(Result).to receive(:view_token_expired?).and_return(false) }

            it 'should succeed when the tokens match' do
              subject
              expect(response).to have_http_status(:success)
            end

            context 'when the token does not match' do
              let(:view_token) { "#{complete_result.view_token}abc123" }

              it 'should be forbidden' do
                subject
                expect(response).to have_http_status(:forbidden)
              end
            end

            context 'when the token is nil' do
              let(:params) { { course_id: course.id, id: complete_result.id } }

              it 'should be forbidden' do
                subject
                expect(response).to have_http_status(:forbidden)
              end

              context 'but the token is saved in the session for this result' do
                context 'when the tokens match' do
                  let(:session) { { view_token: { complete_result.id.to_s => complete_result.view_token } } }

                  it 'should succeed' do
                    subject
                    expect(response).to have_http_status(:success)
                  end
                end

                context 'when the tokens do not match' do
                  let(:session) { { view_token: { complete_result.id.to_s => "#{complete_result.view_token}abc123" } } }

                  it 'should be forbidden' do
                    subject
                    expect(response).to have_http_status(:forbidden)
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  context 'An instructor' do
    before { sign_in instructor }

    context 'accessing set_released_to_students' do
      before do
        get :set_released_to_students, params: { course_id: course.id,
                                                 id: complete_result.id, value: 'true' }, xhr: true
      end

      it { expect(response).to have_http_status(:success) }

      test_assigns_not_nil :result
    end

    it_behaves_like 'showing json data', false

    context 'accessing update_overall_comment' do
      before do
        post :update_overall_comment, params: { course_id: course.id,
                                                id: incomplete_result.id,
                                                result: { overall_comment: SAMPLE_COMMENT } }, xhr: true
        incomplete_result.reload
      end

      it { expect(response).to have_http_status(:success) }

      it 'should update the overall comment' do
        expect(incomplete_result.overall_comment).to eq SAMPLE_COMMENT
      end
    end

    describe '#refresh_view_tokens' do
      subject do
        put :refresh_view_tokens,
            params: { course_id: assignment.course.id, assignment_id: assignment.id, result_ids: ids }
      end

      let(:assignment) { create(:assignment_with_criteria_and_results) }
      let(:results) { assignment.current_results }
      let(:ids) { results.ids }

      it { is_expected.to have_http_status(:success) }

      it 'should regenerate view tokens for all results' do
        view_tokens = results.pluck(:id, :view_token)
        subject
        new_view_tokens = results.pluck(:id, :view_token)
        expect((view_tokens | new_view_tokens).size).to eq 6
      end

      it 'should return a json containing the new tokens' do
        subject
        expect(response.parsed_body).to eq results.pluck(:id, :view_token).to_h.transform_keys(&:to_s)
      end

      context 'some result ids are not associated with the assignment' do
        let(:extra_result) { create(:complete_result) }
        let(:ids) { results.ids + [extra_result.id] }

        it { is_expected.to have_http_status(:success) }

        it 'should regenerate view tokens for all results for the assignment' do
          view_tokens = results.pluck(:id, :view_token)
          subject
          new_view_tokens = results.pluck(:id, :view_token)
          expect((view_tokens | new_view_tokens).size).to eq 6
        end

        it 'should not regenerate view tokens for the extra result' do
          old_token = extra_result.view_token
          subject
          expect(old_token).to eq extra_result.reload.view_token
        end

        it 'should return a json containing the new tokens for the assignment (not the extra one)' do
          subject
          expect(response.parsed_body).to eq results.pluck(:id, :view_token).to_h.transform_keys(&:to_s)
        end
      end
    end

    describe '#update_view_token_expiry' do
      subject do
        put :update_view_token_expiry,
            params: { course_id: assignment.course.id, assignment_id: assignment.id,
                      result_ids: ids, expiry_datetime: expiry_datetime }
      end

      let(:assignment) { create(:assignment_with_criteria_and_results) }
      let(:results) { assignment.current_results }
      let(:ids) { results.ids }
      let(:expiry_datetime) { 1.hour.from_now }

      before { results.update_all view_token_expiry: 1.day.ago }

      it { is_expected.to have_http_status(:success) }

      it 'should update the expiry for all results' do
        subject
        expect(results.pluck(:view_token_expiry)).to all(be_within(1.second).of(expiry_datetime))
      end

      it 'should return a json containing the new dates' do
        subject
        data = response.parsed_body
        results.pluck(:id, :view_token_expiry).each do |id, date|
          expect(Time.zone.parse(data[id.to_s])).to be_within(1.second).of(date)
        end
      end

      context 'when the expiry_datetime is nil' do
        let(:expiry_datetime) { nil }

        it 'should remove the expiry date' do
          subject
          expect(results.pluck(:view_token_expiry)).to eq([expiry_datetime] * results.count)
        end
      end

      context 'some result ids are not associated with the assignment' do
        let(:extra_result) { create(:complete_result) }
        let(:ids) { results.ids + [extra_result.id] }

        it { is_expected.to have_http_status(:success) }

        it 'should set the expiry date for all results for the assignment' do
          subject
          expect(results.pluck(:view_token_expiry)).to all(be_within(1.second).of(expiry_datetime))
        end

        it 'should not set the expiry date for the extra result' do
          old_date = extra_result.view_token_expiry
          subject
          expect(old_date).to eq extra_result.reload.view_token_expiry
        end

        it 'should return a json containing the new tokens for the assignment (not the extra one)' do
          subject
          data = response.parsed_body
          results.pluck(:id, :view_token_expiry).each do |id, date|
            expect(Time.zone.parse(data[id.to_s])).to be_within(1.second).of(date)
          end
        end
      end
    end

    describe '#download_view_tokens' do
      subject do
        put :download_view_tokens,
            params: { course_id: assignment.course.id, assignment_id: assignment.id, result_ids: ids }
      end

      let(:assignment) { create(:assignment_with_criteria_and_results) }
      let(:results) { assignment.current_results }
      let(:ids) { results.ids }

      before { results.update_all view_token_expiry: 1.day.ago }

      it { is_expected.to have_http_status(:success) }

      it 'should return a csv with a header and a row for all results' do
        expect(subject.body.split("\n").count).to eq(1 + results.count)
      end

      shared_examples 'csv contains the right stuff' do
        it 'should return the correct info for all results' do
          data = subject.body.lines
          data.shift # skip header
          data.each do |row|
            group_name, user_name, first_name, last_name, email, id_number,
              view_token, view_token_expiry, url = row.chomp.split(',')
            result = results.find_by(view_token: view_token)
            expect(group_name).to eq result.grouping.group.group_name
            expect(url).to eq view_marks_course_result_url(result.course.id, result.id, view_token: view_token)
            expect(Time.zone.parse(view_token_expiry)).to be_within(1.second).of(result.view_token_expiry)
            user_info = result.grouping.accepted_student_memberships.joins(role: :user).pluck('users.user_name',
                                                                                              'users.first_name',
                                                                                              'users.last_name',
                                                                                              'users.email',
                                                                                              'users.id_number')
            user_info = user_info.map { |info| info.map { |a| a || '' } }
            expect(user_info).to include([user_name, first_name, last_name, email, id_number])
          end
        end
      end

      it_behaves_like 'csv contains the right stuff'
      context 'some result ids are not associated with the assignment' do
        let(:extra_result) { create(:complete_result) }
        let(:ids) { results.ids + [extra_result.id] }

        it { is_expected.to have_http_status(:success) }

        it_behaves_like 'csv contains the right stuff'
      end
    end

    describe '#delete_grace_period_deduction' do
      it 'deletes an existing grace period deduction' do
        expect(grouping.grace_period_deductions.exists?).to be false
        deduction = create(:grace_period_deduction,
                           membership: grouping.accepted_student_memberships.first,
                           deduction: 1)
        expect(grouping.grace_period_deductions.exists?).to be true
        delete :delete_grace_period_deduction,
               params: { course_id: course.id, id: complete_result.id, deduction_id: deduction.id }
        expect(grouping.grace_period_deductions.exists?).to be false
      end

      it 'raises a RecordNotFound error when given a grace period deduction that does not exist' do
        expect do
          delete :delete_grace_period_deduction,
                 params: { course_id: course.id, id: complete_result.id, deduction_id: 100 }
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
                 params: { course_id: course.id, id: complete_result.id, deduction_id: deduction.id }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'when criteria are assigned to graders' do
      let(:assignment) { create(:assignment_with_deductive_annotations) }

      before { assignment.assignment_properties.update(assign_graders_to_criteria: true) }

      context 'when some criteria are assigned to graders' do
        it 'receives all deductive annotation category data' do
          helper_ta = create(:ta)
          first_category = assignment.annotation_categories.where.not(flexible_criterion_id: nil).first
          first_name = "#{first_category.annotation_category_name} [#{first_category.flexible_criterion.name}]"
          other_criterion = create(:flexible_criterion, assignment: assignment)
          assignment.groupings.each do |grouping|
            create(:flexible_mark, criterion: other_criterion, result: grouping.current_result)
          end
          create(:criterion_ta_association, criterion: other_criterion, ta: helper_ta)
          second_category = create(:annotation_category,
                                   assignment: assignment,
                                   flexible_criterion_id: other_criterion.id)
          second_name = "#{second_category.annotation_category_name} [#{second_category.flexible_criterion.name}]"
          post :show, params: { course_id: course.id,
                                id: assignment.groupings.first.current_result,
                                format: :json }, xhr: true

          category_names = [first_name, second_name].sort!
          returned_categories = response.parsed_body['annotation_categories'].pluck('annotation_category_name')
          expect(returned_categories.sort!).to eq category_names
          expect(response.parsed_body['annotation_categories'].size).to eq 2
        end
      end

      context 'when none of the criteria are assigned to graders' do
        it 'receives all deductive annotation category data' do
          deductive_category = assignment.annotation_categories.where.not(flexible_criterion_id: nil).first
          cat_name = "#{deductive_category.annotation_category_name} [#{deductive_category.flexible_criterion.name}]"
          non_deductive_category = create(:annotation_category, assignment: assignment)
          post :show, params: { course_id: course.id,
                                id: assignment.groupings.first.current_result,
                                format: :json }, xhr: true

          category_names = [cat_name, non_deductive_category.annotation_category_name].sort!
          returned_categories = []
          response.parsed_body['annotation_categories'].each do |cat|
            returned_categories += [cat['annotation_category_name']]
          end
          expect(returned_categories.sort!).to eq category_names
          expect(response.parsed_body['annotation_categories'].size).to eq 2
          expect(response.parsed_body['annotation_categories'].count do |cat|
            cat['id'] == deductive_category.id
          end).to eq 1
        end
      end
    end

    context 'when a remark request exists' do
      let(:assignment) { create(:assignment_with_deductive_annotations) }
      let(:complete_result) do
        result = assignment.groupings.first.current_result
        result.update!(marking_state: Result::MARKING_STATES[:complete])
        result
      end
      let(:remarked_result) do
        complete_result.submission.make_remark_result
        complete_result.submission.update(remark_request_timestamp: Time.current)
        complete_result.submission.remark_result
      end
      let(:params) { { course_id: course.id, id: remarked_result.id, format: :json } }

      it 'includes the original result\'s mark data for every assignment criterion' do
        get :show, params: params, xhr: true

        old_marks = response.parsed_body['old_marks']
        expect(old_marks.keys).to match_array assignment.ta_criteria.ids.map(&:to_s)

        expect(old_marks.transform_values { |v| v['mark'] })
          .to eq(complete_result.marks.to_h { |m| [m.criterion_id.to_s, m.mark] })
      end

      context 'when no marks have been overridden' do
        it 'includes the override values for each mark of the original result' do
          get :show, params: params, xhr: true

          old_marks = response.parsed_body['old_marks']
          expect(old_marks.values.pluck('override')).to match_array([false])
        end
      end

      context 'when a mark has been overridden' do
        let(:complete_result) do
          result = assignment.groupings.first.current_result
          result.marks.first.update!(mark: 0, override: true)
          result.update!(marking_state: Result::MARKING_STATES[:complete])
          result
        end

        it 'includes the override values for each mark of the original result' do
          get :show, params: params, xhr: true

          old_marks = response.parsed_body['old_marks']
          expect(old_marks.values.pluck('override')).to match_array([true])
        end
      end
    end

    describe '#print' do
      before do
        get :print, params: { course_id: course.id, id: complete_result.id }
      end

      it 'responds with a success HTTP status' do
        expect(response).to have_http_status :success
      end

      it 'responds with the correct Content-Type' do
        expect(response.header['Content-Type']).to eq('application/pdf')
      end

      it 'responds with the correct filename' do
        filename = URI.decode_www_form_component(response.header['Content-Disposition']).split("UTF-8''").second
        expect(filename).to eq complete_result.print_pdf_filename
      end
    end

    context 'accessing next_grouping' do
      let(:grouping1) { create(:grouping_with_inviter_and_submission) }
      let(:grouping2) { create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment) }
      let(:grouping3) { create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment) }
      let(:grouping4) { create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment) }
      let(:groupings) { [grouping1, grouping2, grouping3, grouping4] }

      before { groupings }

      it_behaves_like 'ta and instructor #next_grouping with filters'
      it_behaves_like 'instructor and ta #next_grouping with different orderings'

      context 'filter by tas' do
        let(:ta1) { create(:ta) }
        let(:ta2) { create(:ta) }

        before do
          create(:ta_membership, role: ta1, grouping: grouping1)
          create(:ta_membership, role: ta1, grouping: grouping3)
          create(:ta_membership, role: ta2, grouping: grouping3)
          create(:ta_membership, role: ta2, grouping: grouping2)
        end

        context 'when a ta has been picked' do
          it 'should return the next group with a larger group name that satisfies the constraints' do
            get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                          id: grouping1.current_result.id,
                                          direction: 1, filterData: { tas: [ta1.user.user_name] } }
            expect(response.parsed_body['next_grouping']['id']).to eq(grouping3.id)
          end

          it 'should not return the next group that doesn\'t satisfy the constraint' do
            get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                          id: grouping1.current_result.id,
                                          direction: 1, filterData: { tas: [ta1.user.user_name] } }
            expect(response.parsed_body['next_grouping']['id']).not_to eq(grouping2.id)
          end
        end

        context 'when multiple tas have been picked' do
          it 'should return the next group with a larger group name that has atleast one of the tas' do
            get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                          id: grouping1.current_result.id,
                                          direction: 1, filterData: { tas: [ta1.user.user_name, ta2.user.user_name] } }
            expect(response.parsed_body['next_grouping']['id']).to eq(grouping2.id)
          end
        end

        context 'when no Ta is picked' do
          it 'should return the next grouping without constraints' do
            get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                          id: grouping1.current_result.id,
                                          direction: 1, filterData: { tas: [] } }
            expect(response.parsed_body['next_grouping']['id']).to eq(grouping2.id)
          end
        end
      end
    end

    context 'accessing get_filtered_grouping_ids' do
      let(:grouping1) { create(:grouping_with_inviter_and_submission) }
      let(:grouping2) { create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment) }
      let(:grouping3) { create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment) }
      let(:groupings) { [grouping1, grouping2, grouping3] }

      before { groupings }

      it 'returns results ordered by group name by default' do
        get :get_filtered_grouping_ids, params: { course_id: course.id, id: grouping1.current_result.id }
        data = response.parsed_body
        returned_grouping_ids = data.pluck('grouping_id')
        expected_order = groupings.sort_by { |g| g.group.group_name }.map(&:id)
        expect(returned_grouping_ids).to eq(expected_order)
      end

      it 'applies filters to the result set' do
        section = create(:section)
        grouping1.inviter.update(section: section)
        grouping2.inviter.update(section: nil)
        grouping3.inviter.update(section: section)

        get :get_filtered_grouping_ids, params: {
          course_id: course.id, id: grouping1.current_result.id,
          filterData: { section: section.name }
        }
        data = response.parsed_body
        returned_grouping_ids = data.pluck('grouping_id')
        expect(returned_grouping_ids).to include(grouping1.id, grouping3.id)
        expect(returned_grouping_ids).not_to include(grouping2.id)
      end
    end

    describe '#random_incomplete_submission' do
      it 'should receive 200 when current grouping has a submission' do
        allow_any_instance_of(Grouping).to receive(:has_submission).and_return true
        get :random_incomplete_submission, params: { course_id: course.id, grouping_id: grouping.id,
                                                     id: incomplete_result.id }
        expect(response).to have_http_status(:ok)
      end

      it 'should receive 200 when current grouping does not have a submission' do
        allow_any_instance_of(Grouping).to receive(:has_submission).and_return false
        get :random_incomplete_submission, params: { course_id: course.id, grouping_id: grouping.id,
                                                     id: incomplete_result.id }
        expect(response).to have_http_status(:ok)
      end

      context 'when there are no more random incomplete submissions' do
        it 'should receive a JSON object with result_id, submission_id and grouping_id as nil' do
          a2 = create(:assignment_with_criteria_and_results)
          a2.groupings.each do |group|
            group.tas.push(ta)
            group.save
          end
          a2.save
          get :random_incomplete_submission, params: { course_id: course.id,
                                                       grouping_id: a2.groupings.first.id,
                                                       id: a2.submissions.first.current_result.id }
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body['result_id']).to be_nil
          expect(response.parsed_body['submission_id']).to be_nil
          expect(response.parsed_body['grouping_id']).to be_nil
        end
      end
    end

    describe '#run_tests' do
      before do
        assignment.update!(enable_test: true,
                           enable_student_tests: true,
                           unlimited_tokens: true,
                           token_start_date: 1.day.ago,
                           remote_autotest_settings_id: 1)
      end

      context 'at least one test-group can be run by instructors' do
        let(:assignment) { create(:assignment_with_test_groups_instructor_runnable) }

        it 'enqueues an AutotestRunJob' do
          params = { course_id: course.id, id: incomplete_result.id }
          expect { post :run_tests, params: params }.to have_enqueued_job(AutotestRunJob)
        end
      end

      context 'no test-group can be run by instructors' do
        let(:assignment) { create(:assignment_with_test_groups_not_instructor_runnable) }

        it 'does not enqueue an AutotestRunJob' do
          params = { course_id: course.id, id: incomplete_result.id }
          expect { post :run_tests, params: params }.not_to have_enqueued_job(AutotestRunJob)
        end
      end
    end
  end

  context 'A TA' do
    before { sign_in ta }

    [:set_released_to_students].each { |route_name| test_unauthorized(route_name) }

    context 'when groups information is anonymized' do
      let(:data) { response.parsed_body }

      before do
        create(:grace_period_deduction, membership: grouping.accepted_student_memberships.first)
        create(:ta_membership, role: ta, grouping: grouping)

        assignment.assignment_properties.update(anonymize_groups: true)
        get :show, params: { course_id: course.id, id: incomplete_result.id }, xhr: true
      end

      it 'should anonymize the group names' do
        expect(data['group_name']).to eq "#{Group.model_name.human} #{data['grouping_id']}"
      end

      it 'should not include any group members' do
        expect(data['members']).to eq []
      end

      it 'should not report any grace token deductions' do
        expect(data['grace_token_deductions']).to eq []
      end
    end

    context 'when criteria are assigned to graders, but not this grader' do
      it 'receives no deductive annotation category data' do
        assignment = create(:assignment_with_deductive_annotations)
        assignment.assignment_properties.update(assign_graders_to_criteria: true)
        non_deductive_category = create(:annotation_category, assignment: assignment)
        create(:ta_membership, role: ta, grouping: assignment.groupings.first)
        post :show, params: { course_id: course.id,
                              id: assignment.groupings.first.current_result,
                              format: :json }, xhr: true

        expect(response.parsed_body['annotation_categories']
                       .first['annotation_category_name']).to eq non_deductive_category.annotation_category_name
        expect(response.parsed_body['annotation_categories'].size).to eq 1
      end
    end

    context 'when criteria are assigned to this grader' do
      let(:data) { response.parsed_body }
      let(:params) { { course_id: course.id, id: incomplete_result.id } }

      before do
        create(:ta_membership, role: ta, grouping: grouping)
        assignment.assignment_properties.update(assign_graders_to_criteria: true)
        create(:criterion_ta_association, criterion: rubric_mark.criterion, ta: ta)
        get :show, params: params, xhr: true
      end

      it 'should include assigned criteria list' do
        expect(data['assigned_criteria']).to eq [rubric_criterion.id]
      end

      context 'when accessing an assignment with deductive annotations' do
        let(:assignment) { create(:assignment_with_deductive_annotations) }

        it 'receives limited annotation category data when assigned ' \
           'to a subset of criteria that have associated categories' do
          other_criterion = create(:flexible_criterion, assignment: assignment)
          assignment.groupings.each do |grouping|
            create(:flexible_mark, criterion: other_criterion, result: grouping.current_result)
          end
          assignment.assignment_properties.update(assign_graders_to_criteria: true)
          create(:criterion_ta_association, criterion: other_criterion, ta: ta)
          create(:ta_membership, role: ta, grouping: assignment.groupings.first)
          other_category = create(:annotation_category,
                                  assignment: assignment,
                                  flexible_criterion_id: other_criterion.id)
          post :show, params: { course_id: course.id,
                                id: assignment.groupings.first.current_result,
                                format: :json }, xhr: true
          expect(response.parsed_body['annotation_categories'].first['annotation_category_name'])
            .to eq "#{other_category.annotation_category_name} [#{other_category.flexible_criterion.name}]"
          expect(response.parsed_body['annotation_categories'].size).to eq 1
        end
      end

      context 'when unassigned criteria are hidden from the grader' do
        before do
          assignment.assignment_properties.update(hide_unassigned_criteria: true)
        end

        it 'should only include marks for the assigned criteria' do
          expected = [[rubric_criterion.class.to_s, rubric_criterion.id]]
          expect(data['marks'].map { |m| [m['criterion_type'], m['id']] }).to eq expected
        end

        context 'when a remark request exists' do
          let(:remarked_result) do
            incomplete_result.submission.make_remark_result
            incomplete_result.submission.update(remark_request_timestamp: Time.current)
            incomplete_result
          end
          let(:params) { { course_id: course.id, id: remarked_result.id } }

          it 'should only include marks for assigned criteria in the remark result' do
            expect(data['old_marks'].keys).to eq [rubric_criterion.id.to_s]
          end
        end
      end
    end

    context 'accessing update_mark' do
      context 'when is assigned to grade the given group\'s submission' do
        before { create(:ta_membership, role: ta, grouping: grouping) }

        it 'should not count completed groupings that are not assigned to the TA' do
          grouping2 = create(:grouping_with_inviter, assignment: assignment)
          create(:version_used_submission, grouping: grouping2)
          grouping2.current_result.update(marking_state: Result::MARKING_STATES[:complete])

          patch :update_mark, params: { course_id: course.id,
                                        id: incomplete_result.id, criterion_id: rubric_mark.criterion_id,
                                        mark: 1 }, xhr: true
          expect(response.parsed_body['num_marked']).to eq 0
        end
      end
    end

    context 'that cannot manage submissions and is not assigned to grade this group\'s submission' do
      context 'accessing edit' do
        it {
          get :edit, params: { course_id: course.id, id: incomplete_result.id }, xhr: true
          expect(response).to have_http_status(:forbidden)
        }
      end

      context 'accessing update_mark' do
        it {
          patch :update_mark, params: { course_id: course.id,
                                        id: incomplete_result.id, criterion_id: rubric_mark.criterion_id,
                                        mark: 1 }, xhr: true
          expect(response).to have_http_status(:forbidden)
        }
      end

      context 'accessing update_overall_comment' do
        it {
          post :update_overall_comment, params: { course_id: course.id,
                                                  id: incomplete_result.id,
                                                  result: { overall_comment: SAMPLE_COMMENT } }, xhr: true
          expect(response).to have_http_status(:forbidden)
        }
      end

      context 'accessing toggle_marking_state' do
        it {
          post :toggle_marking_state, params: { course_id: course.id, id: complete_result.id }, xhr: true
          expect(response).to have_http_status(:forbidden)
        }
      end

      context 'accessing next_grouping' do
        it {
          allow_any_instance_of(Grouping).to receive(:has_submission).and_return true
          get :next_grouping, params: { course_id: course.id, grouping_id: grouping.id, id: incomplete_result.id }
          expect(response).to have_http_status(:forbidden)
        }
      end

      context 'accessing random_incomplete_submission' do
        it {
          allow_any_instance_of(Grouping).to receive(:has_submission).and_return true
          get :random_incomplete_submission,
              params: { course_id: course.id, grouping_id: grouping.id, id: incomplete_result.id }
          expect(response).to have_http_status(:forbidden)
        }
      end

      context 'accessing add_tag' do
        before do
          tag = create(:tag)
          post :add_tag,
               params: { course_id: course.id, id: complete_result.id, tag_id: tag.id }
        end

        it 'doesn\'t add a tag to a grouping' do
          expect(complete_result.submission.grouping.tags.to_a.size).to eq 0
        end

        it { expect(response).to have_http_status(:forbidden) }
      end

      context 'accessing remove_tag' do
        let!(:tag) { create(:tag) }

        before do
          submission.grouping.tags << tag
          post :remove_tag,
               params: { course_id: course.id, id: complete_result.id, tag_id: tag.id }
        end

        it 'doesn\'t remove a tag from the grouping' do
          expect(complete_result.submission.grouping.tags).to eq [tag]
        end

        it { expect(response).to have_http_status(:forbidden) }
      end

      context 'accessing get_annotations' do
        let(:assignment) { create(:assignment_with_deductive_annotations) }
        let(:mark) { assignment.groupings.first.current_result.marks.first }

        it {
          post :get_annotations, params: { course_id: course.id,
                                           id: assignment.groupings.first.current_result,
                                           format: :json }, xhr: true
          expect(response).to have_http_status(:forbidden)
        }
      end

      context 'accessing revert_to_automatic_deductions' do
        let(:assignment) { create(:assignment_with_deductive_annotations) }
        let(:mark) { assignment.groupings.first.current_result.marks.first }

        it {
          mark.update!(override: true, mark: 3.0)
          patch :revert_to_automatic_deductions, params: {
            course_id: course.id,
            id: assignment.groupings.first.current_result,
            criterion_id: mark.criterion_id,
            format: :json
          }, xhr: true
          expect(response).to have_http_status(:forbidden)
        }
      end

      context 'accessing add_extra_mark' do
        let!(:old_mark) { submission.get_latest_result.get_total_mark }

        before do
          post :add_extra_mark, params: { course_id: course.id,
                                          id: submission.get_latest_result.id,
                                          extra_mark: { extra_mark: 1 } }, xhr: true
        end

        it { expect(response).to have_http_status(:forbidden) }

        it 'should not update the total mark' do
          expect(old_mark).to eq(submission.get_latest_result.get_total_mark)
        end
      end

      context 'accessing remove_extra_mark' do
        let!(:extra_mark) { create(:extra_mark_points, result: submission.get_latest_result) }
        let!(:old_mark) do
          submission.get_latest_result.get_total_mark
        end

        before do
          delete :remove_extra_mark, params: { course_id: course.id,
                                               id: submission.get_latest_result.id,
                                               extra_mark_id: extra_mark.id }, xhr: true
        end

        test_no_flash
        it { expect(response).to have_http_status(:forbidden) }

        it 'should not change the total value' do
          expect(old_mark).to eq incomplete_result.get_total_mark
        end
      end

      context 'accessing show' do
        context 'HTTP POST request' do
          it {
            post :show, params: { course_id: course.id,
                                  id: incomplete_result.id,
                                  format: :json }, xhr: true
            expect(response).to have_http_status(:forbidden)
          }
        end

        context 'HTTP GET request' do
          it {
            get :show, params: { course_id: course.id,
                                 id: incomplete_result.id,
                                 format: :json }
            expect(response).to have_http_status(:forbidden)
          }
        end
      end

      context 'accessing get_test_runs_instructors' do
        test_unauthorized(:get_test_runs_instructors)
      end
    end

    context 'with valid permissions' do
      let(:grouping1) { create(:grouping_with_inviter_and_submission) }
      let(:grouping2) { create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment) }
      let(:grouping3) { create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment) }
      let(:grouping4) { create(:grouping_with_inviter_and_submission, assignment: grouping1.assignment) }
      let(:groupings) { [grouping1, grouping2, grouping3, grouping4] }

      before do
        3.times do |i|
          create(:ta_membership, role: ta, grouping: groupings[i])
        end
      end

      context 'accessing random_incomplete_submissions' do
        context 'when graders are not assigned to criteria' do
          it 'returns no result when there are no other incomplete result' do
            grouping2.current_result.update!(marking_state: Result::MARKING_STATES[:complete])
            grouping3.current_result.update!(marking_state: Result::MARKING_STATES[:complete])
            get :random_incomplete_submission,
                params: { course_id: course.id, grouping_id: grouping1.id, id: grouping1.current_result.id }
            expect(response.parsed_body.symbolize_keys).to eq({
              grouping_id: nil, submission_id: nil, result_id: nil
            })
          end

          it 'returns an incomplete result when there is another incomplete result' do
            grouping2.current_result.update!(marking_state: Result::MARKING_STATES[:complete])
            get :random_incomplete_submission,
                params: { course_id: course.id, grouping_id: grouping1.id, id: grouping1.current_result.id }
            expect(response.parsed_body.symbolize_keys).to eq({
              grouping_id: grouping3.id, submission_id: grouping3.current_submission_used.id,
              result_id: grouping3.current_result.id
            })
          end
        end
      end

      context 'when graders are assigned to criteria' do
        let(:criterion) { create(:flexible_criterion, assignment: grouping1.assignment) }

        before do
          grouping1.assignment.update!(assign_graders_to_criteria: true)
          grouping1.assignment.groupings.find_each do |grouping|
            grouping.current_result.marks.find_or_create_by(criterion_id: criterion.id)
          end
        end

        context 'when the TA is assigned a criterion' do
          before { create(:criterion_ta_association, ta: ta, criterion: criterion) }

          it 'returns no result when all other results have a mark for the assigned criterion' do
            grouping2.current_result.marks.find_by(criterion_id: criterion.id).update!(mark: 0)
            grouping3.current_result.marks.find_by(criterion_id: criterion.id).update!(mark: 0)
            get :random_incomplete_submission,
                params: { course_id: course.id, grouping_id: grouping1.id, id: grouping1.current_result.id }
            expect(response.parsed_body.symbolize_keys).to eq({
              grouping_id: nil, submission_id: nil, result_id: nil
            })
          end

          it 'returns an unmarked result when there is another result with no mark for the assigned criterion' do
            grouping2.current_result.marks.find_by(criterion_id: criterion.id).update!(mark: 0)

            get :random_incomplete_submission,
                params: { course_id: course.id, grouping_id: grouping1.id, id: grouping1.current_result.id }
            expect(response.parsed_body.symbolize_keys).to eq({
              grouping_id: grouping3.id, submission_id: grouping3.current_submission_used.id,
              result_id: grouping3.current_result.id
            })
          end
        end

        context 'when the TA is not assigned a criterion' do
          it 'returns no result' do
            get :random_incomplete_submission,
                params: { course_id: course.id, grouping_id: grouping1.id, id: grouping1.current_result.id }
            expect(response.parsed_body.symbolize_keys).to eq({
              grouping_id: nil, submission_id: nil, result_id: nil
            })
          end
        end
      end

      context 'accessing next_grouping' do
        context 'ta and instructor #next_grouping with filters' do
          before do
            create(:ta_membership, role: ta, grouping: groupings[3])
          end

          it_behaves_like 'ta and instructor #next_grouping with filters'
        end

        it_behaves_like 'instructor and ta #next_grouping with different orderings'
        context 'filter by tas' do
          let(:ta1) { create(:ta) }
          let(:ta2) { create(:ta) }

          before do
            create(:ta_membership, role: ta1, grouping: grouping1)
            create(:ta_membership, role: ta1, grouping: grouping3)
            create(:ta_membership, role: ta2, grouping: grouping3)
            create(:ta_membership, role: ta2, grouping: grouping2)
          end

          context 'when a ta has been picked' do
            it 'should return the next group with a larger group name and NOT filter by selected ta' do
              get :next_grouping, params: { course_id: course.id, grouping_id: grouping1.id,
                                            id: grouping1.current_result.id,
                                            direction: 1, filterData: { tas: [ta1.user.user_name] } }
              expect(response.parsed_body['next_grouping']['id']).to eq(grouping2.id)
            end
          end
        end
      end

      context 'accessing get_filtered_grouping_ids' do
        it 'returns only groupings assigned to the TA' do
          get :get_filtered_grouping_ids, params: { course_id: course.id, id: grouping1.current_result.id }
          data = response.parsed_body
          returned_grouping_ids = data.pluck('grouping_id')
          expect(returned_grouping_ids).not_to include(grouping4.id)
          expect(returned_grouping_ids.length).to eq(3)
        end
      end
    end
  end
end
