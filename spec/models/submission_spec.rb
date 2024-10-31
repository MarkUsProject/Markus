describe Submission do
  describe 'validations' do
    it { is_expected.to have_many(:submission_files) }
    it { is_expected.to have_many(:test_runs) }
    it { is_expected.to have_many(:test_group_results).through(:test_runs) }
    it { is_expected.to have_one(:course) }
  end

  context 'automatically create a result' do
    it 'should create result automatically' do
      submission = create(:submission)
      expect(submission).not_to be_nil
    end

    it 'should have marking automatically set to be incomplete' do
      submission = create(:submission)
      expect(submission.get_latest_result.marking_state).to eq(Result::MARKING_STATES[:incomplete])
    end

    it 'should create a new remark result' do
      submission = create(:submission)
      submission.update(remark_request_timestamp: Time.current)
      submission.make_remark_result
      expect(submission.remark_result).not_to be_nil
      expect(submission.remark_result.marking_state).to eq(Result::MARKING_STATES[:incomplete])
    end
  end

  context 'handle remark requests' do
    let(:assignment) { create(:assignment_with_criteria_and_results) }
    let(:submission) do
      submission = assignment.groupings.first.current_submission_used
      submission.update(remark_request_timestamp: Time.current)
      submission
    end
    let(:extra_mark) { create(:extra_mark, result: submission.results.first) }

    it 'should have proper remarking status' do
      submission.make_remark_result
      expect(submission.has_remark?).to be true
      expect(submission.remark_submitted?).to be true
    end

    it 'should create marks with the same values as the original result' do
      submission.make_remark_result

      expect(submission.remark_result.marks.pluck(:criterion_id, :mark))
        .to match_array(submission.get_original_result.marks.pluck(:criterion_id, :mark))
    end

    it 'should create marks with the same override status as the original result' do
      submission.current_result.marks.first.update(override: true)
      submission.make_remark_result

      expect(submission.remark_result.marks.pluck(:criterion_id, :override))
        .to match_array(submission.get_original_result.marks.pluck(:criterion_id, :override))
    end

    it 'should create another extra mark if there was one originally' do
      extra_mark
      submission.make_remark_result
      marks = ExtraMark.where(result_id: [submission.get_original_result.id, submission.remark_result.id])
      expect(marks.count).to eq(2)
    end

    it 'should copy extra marks from the original result to the remark request' do
      extra_mark
      submission.make_remark_result
      marks = ExtraMark.where(result_id: [submission.get_original_result.id, submission.remark_result.id])
      attributes = marks.pluck('description', 'extra_mark', 'unit')
      expect(attributes[0]).to eq(attributes[1])
    end
  end

  describe 'submission with a remark result created but not submitted' do
    before do
      @result = create(:result, marking_state: Result::MARKING_STATES[:incomplete])
      @submission = @result.submission
      @submission.update(remark_request_timestamp: Time.current)
      @submission.make_remark_result
      @submission.remark_result.update(remark_request_submitted_at: nil)
    end

    describe 'handle remarks with updates' do
      it 'should return true on has_remark? call' do
        expect(@submission.has_remark?).to be true
      end
    end

    it 'should return false on remark_submitted? call' do
      expect(@submission.remark_submitted?).to be false
    end
  end

  describe 'A submission with no remark results' do
    before do
      @submission = create(:submission)
      @submission.save
    end

    it 'return false on has_remark? call' do
      expect(@submission.has_remark?).to be false
    end

    it 'return false on remark_submitted? call' do
      expect(@submission.remark_submitted?).to be false
    end
  end

  describe 'The Submission class' do
    it 'create a remark result' do
      s = create(:submission)
      s.update(remark_request_timestamp: Time.current)
      s.make_remark_result
      expect(s.remark_result).not_to be_nil
      expect(s.remark_result.marking_state).to eq Result::MARKING_STATES[:incomplete]
    end
  end

  describe '#get_visible_result' do
    let(:submission) { create(:submission) }
    let(:released_result) { create(:released_result, submission: submission) }
    let(:remark_result) { create(:remark_result, submission: submission) }
    let(:released_remark_result) { create(:remark_result, submission: submission, released_to_students: true) }

    context 'when the remark result is released' do
      before do
        released_remark_result
      end

      it 'should return the remark result' do
        expect(submission.get_visible_result).to eq released_remark_result
      end
    end

    context 'when the original result is released' do
      before do
        released_result
        remark_result
      end

      it 'should return the original result' do
        expect(submission.get_visible_result).to eq released_result
      end
    end

    context 'when the original result is not released' do
      before do
        remark_result
      end

      it 'should return the original result' do
        expect(submission.get_visible_result).to eq submission.get_original_result
      end
    end

    context 'when there are multiple results released to students' do
      before do
        released_result
        released_remark_result
      end

      it 'should return the remark' do
        expect(submission.get_visible_result).to eq released_remark_result
      end
    end
  end

  describe '#set_autotest_marks' do
    let(:submission) { create(:submission) }
    let(:assignment) { submission.assignment }
    let(:result) { submission.get_latest_result }
    let!(:criterion) { create(:flexible_criterion, assignment: assignment) }
    let!(:mark) { create(:mark, criterion: criterion, result: result) }
    let(:test_group) { create(:test_group, assignment: assignment, criterion: criterion) }
    let(:test_run) { create(:test_run, grouping: submission.grouping, submission: submission) }

    context 'when a TestGroupResult succeeded with no error' do
      before do
        create(:test_group_result, test_group: test_group, test_run: test_run,
                                   error_type: nil, marks_earned: 1, marks_total: 1)
      end

      it 'updates the result mark' do
        assignment.ta_criteria.reload
        submission.set_autotest_marks
        mark.reload
        expect(mark.mark).to eq criterion.max_mark
      end
    end

    context 'when a TestGroupResult timed out' do
      before do
        create(:test_group_result, test_group: test_group, test_run: test_run,
                                   error_type: TestGroupResult::ERROR_TYPE[:timeout])
      end

      it 'does not update the result mark' do
        assignment.ta_criteria.reload
        submission.set_autotest_marks
        mark.reload
        expect(mark.mark).to be_nil
      end
    end
  end

  describe '#copy_grading_data' do
    let(:assignment) { create(:assignment_with_criteria_and_results) }

    before do
      @original_submission = assignment.groupings.first.current_submission_used
      @original_result = @original_submission.current_result
      @new_submission = create(:submission,
                               grouping: @original_submission.grouping)

      # explicitly copy submission files to the new submission (this is normally done on collection)
      @original_submission.submission_files.each do |submission_file|
        create(:submission_file_with_repo, submission: @new_submission, filename: submission_file.filename)
      end

      @new_submission.reload.copy_grading_data(@original_submission)
      @new_result = @new_submission.reload.current_result
    end

    context 'for feedback files on the new submission' do
      let(:assignment) { create(:assignment_with_criteria_and_results_and_feedback_files) }

      it 'creates the correct number of new feedback files' do
        expect(@new_submission.feedback_files.size).to eq(@original_submission.feedback_files.size)
        expect(@new_submission.feedback_files.ids.sort).not_to eq(@original_submission.feedback_files.ids.sort)
      end

      it 'retains the file name on each new feedback file' do
        # cannot compare by order here because there is no common field between the two, so
        # instead we check the set of filenames is equal
        expect(@new_submission.feedback_files.map(&:filename).sort).to eq(@original_submission
          .feedback_files.map(&:filename).sort)
      end
    end

    context 'for automated tests on the new submission' do
      let(:assignment) { create(:assignment_with_criteria_and_test_results_and_feedback_files) }

      it 'creates the correct number of new test runs' do
        expect(@new_submission.test_runs.size).to eq(@original_submission.test_runs.size)
        expect(@new_submission.test_runs.ids.sort).not_to eq(@original_submission.test_runs.ids.sort)
      end

      context 'for each new test run' do
        it 'creates the correct number of new test group results' do
          @new_submission.test_runs.zip(@original_submission.test_runs).each do |new_test_run, old_test_run|
            expect(new_test_run.test_group_results.size).to eq(old_test_run.test_group_results.size)
            expect(new_test_run.test_group_results.ids.sort).not_to eq(old_test_run.test_group_results.ids.sort)
          end
        end

        context 'for each new test group results' do
          it 'creates the correct number of new test results' do
            @new_submission.test_runs.zip(@original_submission.test_runs).each do |new_test_run, old_test_run|
              new_test_run.test_group_results.zip(old_test_run.test_group_results).each do |new_tgr, old_tgr|
                expect(new_tgr.test_results.size).to eq(old_tgr.test_results.size)
                expect(new_tgr.test_results.ids.sort).not_to eq(old_tgr.test_results.ids.sort)
              end
            end
          end

          it 'creates the correct number of new feedback files' do
            @new_submission.test_runs.zip(@original_submission.test_runs).each do |new_test_run, old_test_run|
              new_test_run.test_group_results.zip(old_test_run.test_group_results).each do |new_tgr, old_tgr|
                expect(new_tgr.feedback_files.size).to eq(old_tgr.feedback_files.size)
                expect(new_tgr.feedback_files.ids.sort).not_to eq(old_tgr.feedback_files.ids.sort)
              end
            end
          end
        end
      end
    end

    context 'for the new result that is created' do
      context 'for remark data' do
        let(:assignment) { create(:assignment_with_criteria_and_results_with_remark) }

        it 'does not copy over remark information' do
          expect(@new_result.remark_request_submitted_at).to be_nil
        end
      end

      context 'for marks' do
        it 'creates the correct number of new marks' do
          expect(@new_result.marks.size).to eq(@original_result.marks.size)
          expect(@new_result.marks.ids.sort).not_to eq(@original_result.marks.ids.sort)
        end

        it 'retains the correct mark values' do
          expect(@new_result.marks.order(:criterion_id).map(&:mark)).to eq(@original_result
            .marks.order(:criterion_id).map(&:mark))
        end
      end

      context 'for annotations' do
        let(:assignment) { create(:assignment_with_deductive_annotations_and_submission_files) }

        it 'creates the correct number of new annotations' do
          expect(@new_result.annotations.size).to eq(@original_result.annotations.size)
          expect(@new_result.annotations.ids.sort).not_to eq(@original_result.annotations.ids.sort)
        end

        it 'retains the mark deductions from deductive annotations' do
          expect(@new_result.marks.order(:criterion_id).map(&:calculate_deduction)).to eq(@original_result
            .marks.order(:criterion_id).map(&:calculate_deduction))
        end

        it 'retains the text from each annotation' do
          expect(@new_result.annotations.order(:annotation_text_id).map do |a|
            a.annotation_text.content
          end).to eq(@original_result.annotations.order(:annotation_text_id).map do |a|
            a.annotation_text.content
          end)
        end

        context 'when no submission files in the original submission are present in the new submission' do
          let(:assignment) { create(:assignment_with_deductive_annotations) }

          before do
            # overwrite new_submission to purposefully not have any copied submission files
            @new_submission = create(:submission,
                                     grouping: @original_submission.grouping)
            @new_submission.reload.copy_grading_data(@original_submission)
            @new_result = @new_submission.reload.current_result
          end

          it 'does not retain any annotations' do
            expect(@new_result.annotations).to be_empty
          end
        end
      end

      context 'for extra marks' do
        let(:assignment) { create(:assignment_with_criteria_and_results_and_extra_marks) }

        it 'creates the correct number of new extra marks' do
          expect(@new_result.extra_marks.size).to eq(@original_result.extra_marks.size)
          expect(@new_result.extra_marks.ids.sort).not_to eq(@original_result.extra_marks.ids.sort)
        end

        it 'retains the correct mark values' do
          # no common field so compare by full array
          expect(@new_result.extra_marks.map(&:extra_mark).sort).to eq(@original_result.extra_marks
            .map(&:extra_mark).sort)
        end

        it 'does not copy over extra marks in percentage format' do
          expect(@new_result.extra_marks.where(unit: 'percentage')).to be_empty
        end
      end
    end
  end
end
