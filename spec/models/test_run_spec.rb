describe TestRun do
  subject { create(:test_run, status: :in_progress) }

  it { is_expected.to have_many(:test_group_results) }
  it { is_expected.to belong_to(:test_batch).optional }
  it { is_expected.to belong_to(:submission).optional }
  it { is_expected.to belong_to(:grouping) }
  it { is_expected.to belong_to(:role) }
  it { is_expected.to have_one(:course) }

  describe 'validations' do
    describe 'autotest_test_id_uniqueness' do
      before do
        allow_any_instance_of(AutotestSetting).to receive(:register_autotester)
        create(:course, autotest_setting: create(:autotest_setting))
        create(:test_run, autotest_test_id: 1, status: :in_progress)
      end

      context 'a test run exists with the same associated autotest_settings' do
        let(:test_run) { create(:test_run, autotest_test_id: autotest_test_id, status: :in_progress) }

        context 'and the same autotest_test_id' do
          let(:autotest_test_id) { 1 }

          it 'should not be valid' do
            expect { test_run }.to raise_exception(ActiveRecord::RecordInvalid)
          end
        end

        context 'and a different autotest_test_id' do
          let(:autotest_test_id) { 2 }

          it 'should be valid' do
            expect { test_run }.not_to raise_exception
          end
        end
      end

      context 'a test run exists with a different associated autotest_settings' do
        let(:other_course) { create(:course, autotest_setting: create(:autotest_setting)) }
        let(:other_role) { create(:instructor, course: other_course) }
        let(:other_assignment) do
          create(:assignment,
                 assignment_properties_attributes: { remote_autotest_settings_id: 11 },
                 course: other_course)
        end
        let(:other_grouping) { create(:grouping, assignment: other_assignment) }
        let(:test_run) do
          build(:test_run, grouping: other_grouping, role: other_role,
                           autotest_test_id: autotest_test_id, status: :in_progress)
        end

        context 'and the same autotest_test_id' do
          let(:autotest_test_id) { 1 }

          it 'should be valid' do
            expect { test_run }.not_to raise_exception
          end
        end

        context 'and a different autotest_test_id' do
          let(:autotest_test_id) { 2 }

          it 'should be valid' do
            expect { test_run }.not_to raise_exception
          end
        end
      end
    end
  end

  it_behaves_like 'course associations'

  describe '#cancel' do
    before { test_run.cancel }

    context 'is in progress' do
      let(:test_run) { create(:test_run, status: :in_progress, autotest_test_id: 1) }

      it 'should update the status to cancelled' do
        expect(test_run.reload.status).to eq('cancelled')
      end

      it 'should unset the autotest_test_id' do
        expect(test_run.reload.autotest_test_id).to be_nil
      end
    end

    context 'is not in progress' do
      let(:test_run) { create(:test_run) }

      it 'should not update the status to cancelled' do
        expect(test_run.reload.status).to eq('complete')
      end
    end
  end

  describe '#failure' do
    let(:problems) { 'some problem' }

    before { test_run.failure(problems) }

    context 'is in progress' do
      let(:test_run) { create(:test_run, status: :in_progress, autotest_test_id: 1) }

      it 'should update the status to cancelled' do
        expect(test_run.reload.status).to eq('failed')
      end

      it 'should unset the autotest_test_id' do
        expect(test_run.reload.autotest_test_id).to be_nil
      end
    end

    context 'is not in progress' do
      let(:test_run) { create(:test_run) }

      it 'should not update the status to cancelled' do
        expect(test_run.reload.status).to eq('complete')
      end
    end
  end

  describe '.all_test_categories' do
    it 'should return [instructor, student]' do
      expect(TestRun.all_test_categories).to contain_exactly('instructor', 'student')
    end
  end

  describe '#update_results!' do
    let(:assignment) { create(:assignment) }
    let(:grouping) { create(:grouping, assignment: assignment) }
    let!(:existing_tag) { create(:tag, name: 'existing_tag', assessment: assignment) }
    let(:test_run) { create(:test_run, status: :in_progress, grouping: grouping, autotest_test_id: 1) }
    let(:criterion) { create(:flexible_criterion, max_mark: 2, assignment: assignment) }
    let(:test_group) { create(:test_group, criterion: criterion, assignment: assignment) }
    let(:png_file_content) { fixture_file_upload('page_white_text.png').read }
    let(:text_file_content) { 'test123' }
    let(:overall_comment1) { 'test comment 1' }
    let(:existing_comment) { 'existing comment' }
    let(:submission_file_text) { create(:submission_file, filename: 'test_compressed.txt', path: '/') }
    let(:submission_file_image) { create(:submission_file, filename: 'test_compressed.png', path: '/') }
    let(:test1) { { name: :test1, status: :pass, marks_earned: 1, marks_total: 1, output: 'output', time: 1 } }
    let(:test2) { { name: :test2, status: :fail, marks_earned: 0, marks_total: 1, output: 'failure', time: nil } }
    let(:tests) { [test1, test2] }
    let(:stderr) { '' }
    let(:results) do
      { status: :finished,
        error: nil,
        test_groups: [{
          time: 10,
          timeout: nil,
          stderr: stderr,
          malformed: '',
          extra_info: { test_group_id: test_group.id },
          feedback: [
            { filename: 'test.txt', mime_type: 'text', content: text_file_content },
            {
              filename: 'test_compressed.txt',
              mime_type: 'text',
              compression: 'gzip',
              content: Zlib.gzip(text_file_content)
            },
            { filename: 'test.png', mime_type: 'image/png', content: png_file_content },
            {
              filename: 'test_compressed.png',
              mime_type: 'image/png',
              compression: 'gzip',
              content: Zlib.gzip(png_file_content)
            }
          ],
          tests: tests
        }] }.deep_stringify_keys
    end

    context 'extra marks (bonus_comments)' do
      let(:base_results) { results.deep_dup } # keep original intact

      shared_context 'bonus setup' do
        before do
          submission.reload
          submission.current_result.update!(released_to_students: false)
          allow(grouping).to receive(:current_submission_used).and_return(submission)
        end
      end

      context 'when the test run has a submission and a valid POINTS bonus' do
        include_context 'bonus setup'

        let(:submission) { create(:version_used_submission, grouping: grouping) }
        let(:test_run) do
          create(:test_run, status: :in_progress, submission: submission, grouping: grouping, autotest_test_id: 1)
        end

        before do
          base_results['test_groups'].first['tests'].first['extra_properties'] = {
            'bonus_comments' => [
              {
                'mark' => 3,
                'unit' => 'points',
                'description' => 'this is a test comment'
              }
            ]
          }
        end

        it 'creates an ExtraMark on the submission result' do
          expect { test_run.update_results!(base_results) }.to change { ExtraMark.count }.by(1)
          em = ExtraMark.last
          expect(em.unit).to eq ExtraMark::POINTS
          expect(em.extra_mark).to eq 3
          expect(em.result_id).to eq submission.current_result.id
          expect(em.description).to eq 'this is a test comment'
        end

        it 'adds the points to the test_group_result.marks_earned' do
          test_run.update_results!(base_results)
          tgr = TestGroupResult.find_by(test_group_id: test_group.id, test_run_id: test_run.id)
          # baseline earned = 1 (from first test), +3 bonus = 4 total
          expect(tgr.marks_earned).to eq 4
          expect(tgr.marks_total).to eq 2 # unchanged
        end
      end

      context 'when the test run has a submission and a non-POINTS unit (percentage)' do
        include_context 'bonus setup'

        let(:submission) { create(:version_used_submission, grouping: grouping) }
        let(:test_run) do
          create(:test_run, status: :in_progress, submission: submission, grouping: grouping, autotest_test_id: 1)
        end

        before do
          base_results['test_groups'].first['tests'].first['extra_properties'] = {
            'bonus_comments' => [
              { 'unit' => ExtraMark::PERCENTAGE, 'mark' => 10, 'description' => '10% bump' }
            ]
          }
        end

        it 'creates an ExtraMark but does not change marks_earned' do
          expect { test_run.update_results!(base_results) }.to change { ExtraMark.count }.by(1)
          tgr = TestGroupResult.find_by(test_group_id: test_group.id, test_run_id: test_run.id)
          # baseline earned remains 1 since non-POINTS units don’t add to marks_earned
          expect(tgr.marks_earned).to eq 1
          expect(tgr.marks_total).to eq 2
        end
      end

      context 'when the unit is invalid' do
        let(:submission) { create(:version_used_submission, grouping: grouping) }
        let(:test_run) do
          create(:test_run, status: :in_progress, submission: submission, grouping: grouping, autotest_test_id: 1)
        end

        before do
          base_results['test_groups'].first['tests'].first['extra_properties'] = {
            'bonus_comments' => [
              { 'unit' => 'bananas', 'mark' => 99, 'description' => 'nope' }
            ]
          }
        end

        it 'ignores the comment and does not create an ExtraMark nor change marks' do
          expect { test_run.update_results!(base_results) }.not_to(change { ExtraMark.count })
          tgr = TestGroupResult.find_by(test_group_id: test_group.id, test_run_id: test_run.id)
          expect(tgr.marks_earned).to eq 1
          expect(tgr.marks_total).to eq 2
        end
      end

      context 'when bonus_comments is not an array' do
        let(:submission) { create(:version_used_submission, grouping: grouping) }
        let(:test_run) do
          create(:test_run, status: :in_progress, submission: submission, grouping: grouping, autotest_test_id: 1)
        end

        before do
          base_results['test_groups'].first['tests'].first['extra_properties'] = {
            'bonus_comments' => 'not-an-array'
          }
        end

        it 'does nothing' do
          expect { test_run.update_results!(base_results) }.not_to(change { ExtraMark.count })
          tgr = TestGroupResult.find_by(test_group_id: test_group.id, test_run_id: test_run.id)
          expect(tgr.marks_earned).to eq 1
          expect(tgr.marks_total).to eq 2
        end
      end

      context 'when bonus_comments is missing' do
        let(:submission) { create(:version_used_submission, grouping: grouping) }
        let(:test_run) do
          create(:test_run, status: :in_progress, submission: submission, grouping: grouping, autotest_test_id: 1)
        end

        it 'does nothing' do
          expect { test_run.update_results!(base_results) }.not_to(change { ExtraMark.count })
          tgr = TestGroupResult.find_by(test_group_id: test_group.id, test_run_id: test_run.id)
          expect(tgr.marks_earned).to eq 1
          expect(tgr.marks_total).to eq 2
        end
      end

      context 'when there is no submission result (no submission on the test run)' do
        let(:test_run) { create(:test_run, status: :in_progress, grouping: grouping, autotest_test_id: 1) }

        before do
          base_results['test_groups'].first['tests'].first['extra_properties'] = {
            'bonus_comments' => [
              { 'unit' => ExtraMark::POINTS, 'mark' => 5, 'description' => 'should be ignored' }
            ]
          }
        end

        it 'does not create ExtraMark and does not change marks_earned' do
          expect { test_run.update_results!(base_results) }.not_to(change { ExtraMark.count })
          tgr = TestGroupResult.find_by(test_group_id: test_group.id, test_run_id: test_run.id)
          # no submission => add_extra_marks_to_test! returns 0, so only earned = 1 baseline
          expect(tgr.marks_earned).to eq 1
          expect(tgr.marks_total).to eq 2
        end
      end
    end

    context 'when there are feedback files' do
      let(:feedback_files) { test_group.test_group_results.first.feedback_files }

      before { test_run.update_results!(results) }

      it 'should create 4 feedback files' do
        expect(feedback_files.count).to eq 4
      end

      it 'should create a feedback file from uncompressed text' do
        expect(feedback_files.find_by(filename: 'test.txt').file_content).to eq(text_file_content)
      end

      it 'should create a feedback file from compressed text' do
        expect(feedback_files.find_by(filename: 'test_compressed.txt').file_content).to eq(text_file_content)
      end

      it 'should create a feedback file from uncompressed binary data' do
        expect(feedback_files.find_by(filename: 'test.png').file_content).to eq(png_file_content)
      end

      it 'should create a feedback file from compressed binary data' do
        expect(feedback_files.find_by(filename: 'test_compressed.png').file_content).to eq(png_file_content)
      end

      context 'when a submission exists' do
        let(:submission) { create(:submission, grouping: grouping) }
        let(:test_run) do
          create(:test_run, status: :in_progress,
                            grouping: grouping,
                            autotest_test_id: 1, submission: submission)
        end

        it 'should associate the files with a submission' do
          expect(feedback_files.first.submission).not_to be_nil
        end
      end

      context 'when feedback files exceed the file size limit' do
        let(:text_file_content) { SecureRandom.alphanumeric(assignment.course.max_file_size + 10) }
        let(:png_file_content) { text_file_content }
        let(:size_diff) { text_file_content.size - assignment.course.max_file_size }
        let(:expected_content) do
          I18n.t('oversize_feedback_file',
                 file_size: ActiveSupport::NumberHelper.number_to_human_size(size_diff),
                 max_file_size: assignment.course.max_file_size / 1_000_000)
        end

        it 'should replace the content with an error message' do
          expect(feedback_files.find_by(filename: 'test.txt').file_content).to eq(expected_content)
        end

        it 'should set the mime type to text' do
          expect(feedback_files.find_by(filename: 'test.png').mime_type).to eq('text')
        end

        it 'should replace the content of zipped files when the unzipped file is over the limit' do
          expect(feedback_files.find_by(filename: 'test_compressed.png').file_content).to eq(expected_content)
        end
      end
    end

    context 'there is a failure reported' do
      before { results['status'] = 'failed' }

      it 'should change the status to failure' do
        expect { test_run.update_results!(results) }.to change { test_run.status }.to('failed')
      end

      it 'should not update criteria marks' do
        expect { test_run.update_results!(results) }.not_to(change { criterion.reload.marks.count })
      end

      it 'should unset the autotest_test_id' do
        test_run.update_results!(results)
        expect(test_run.reload.autotest_test_id).to be_nil
      end
    end

    context 'there is a success reported' do
      let(:test_group_result) { TestGroupResult.find_by(test_group_id: test_group.id, test_run_id: test_run.id) }

      it 'should update the status to completed' do
        expect { test_run.update_results!(results) }.to change { test_run.status }.to('complete')
      end

      it 'should unset the autotest_test_id' do
        test_run.update_results!(results)
        expect(test_run.reload.autotest_test_id).to be_nil
      end

      context 'there is an error message' do
        before { results['error'] = 'error message' }

        it 'should update the problems' do
          expect { test_run.update_results!(results) }.to change { test_run.problems }.to('error message')
        end
      end

      it 'should create a test group result' do
        test_run.update_results!(results)
        expect(test_group_result).not_to be_nil
      end

      context 'setting the extra_info attribute' do
        context 'when both stderr and malformed are blank' do
          it 'should set extra_info to nil' do
            test_run.update_results!(results)
            expect(test_group_result.extra_info).to be_nil
          end
        end

        context 'when stderr is not nil' do
          it 'should set extra_info' do
            results['test_groups'].first['stderr'] = 'error'
            test_run.update_results!(results)
            msg = I18n.t('automated_tests.results.extra_stderr', extra: 'error')
            expect(test_group_result.extra_info).to eq msg
          end
        end

        context 'when malformed is not nil' do
          it 'should set extra_info' do
            results['test_groups'].first['malformed'] = 'error'
            test_run.update_results!(results)
            msg = I18n.t('automated_tests.results.extra_malformed', extra: 'error')
            expect(test_group_result.extra_info).to eq msg
          end
        end

        context 'when both are not nil' do
          it 'should set extra_info' do
            results['test_groups'].first['stderr'] = 'stderr error'
            results['test_groups'].first['malformed'] = 'malformed error'
            test_run.update_results!(results)
            msg = I18n.t('automated_tests.results.extra_stderr', extra: 'stderr error')
            msg += I18n.t('automated_tests.results.extra_malformed', extra: 'malformed error')
            expect(test_group_result.extra_info).to eq msg
          end
        end
      end

      context 'when the marks_total and marks_earned values are set' do
        it 'should set the marks_total to 2' do
          test_run.update_results!(results)
          expect(test_group_result.marks_total).to eq 2
        end

        it 'should set the marks_earned to 1' do
          test_run.update_results!(results)
          expect(test_group_result.marks_earned).to eq 1
        end
      end

      context 'when the marks_total and marks_earned values are not set' do
        before { results['test_groups'].first['tests'].each { |t| t['marks_earned'] = t['marks_total'] = nil } }

        it 'should set the marks_total to 0' do
          test_run.update_results!(results)
          expect(test_group_result.marks_total).to eq 0
        end

        it 'should set the marks_earned to 0' do
          test_run.update_results!(results)
          expect(test_group_result.marks_earned).to eq 0
        end
      end

      context 'when time is set' do
        it 'should set the time attribute' do
          test_run.update_results!(results)
          expect(test_group_result.time).to eq 10
        end
      end

      context 'when time is not set' do
        it 'should set the time attribute' do
          results['test_groups'].first['time'] = nil
          test_run.update_results!(results)
          expect(test_group_result.time).to eq 0
        end
      end

      context 'when tests are empty' do
        before { results['test_groups'].first['tests'] = [] }

        context 'when timeout is set' do
          before { results['test_groups'].first['timeout'] = 5 }

          it 'should set error_type to timeout' do
            test_run.update_results!(results)
            expect(test_group_result.error_type).to eq TestGroupResult::ERROR_TYPE[:timeout].to_s
          end
        end

        context 'when timeout is not set' do
          it 'should set error_type to no_result' do
            test_run.update_results!(results)
            expect(test_group_result.error_type).to eq TestGroupResult::ERROR_TYPE[:no_results].to_s
          end
        end
      end

      context 'when tests are not empty' do
        context 'when timeout is set' do
          before { results['test_groups'].first['timeout'] = 5 }

          it 'should set error_type to timeout' do
            test_run.update_results!(results)
            expect(test_group_result.error_type).to be_nil
          end
        end

        context 'when timeout is not set' do
          it 'should set error_type to no_result' do
            test_run.update_results!(results)
            expect(test_group_result.error_type).to be_nil
          end
        end
      end

      context 'when a test produces an error' do
        let(:test2) do
          {
            name: :test1,
            status: :fail,
            marks_earned: 1,
            marks_total: 1,
            output: 'failure',
            time: nil
          }
        end

        before do
          test_run.update_results!(results)
        end

        it 'should create a test group result' do
          expect(test_group_result).not_to be_nil
        end

        it 'should create a test group result with the error message as extra_info' do
          expect(test_group_result.extra_info).to eq 'test1 - Validation failed: Test Name has already been taken'
        end

        it 'should still add marks_total for the tests that passed' do
          expect(test_group_result.marks_total).to eq 1
        end

        it 'should still add marks_earned for the tests that passed' do
          expect(test_group_result.marks_earned).to eq 1
        end

        it 'should still create test results for the passing tests' do
          expect(test_group_result.test_results.size).to eq 1
        end

        context 'when multiple errors occur' do
          let(:test3) do
            {
              name: :test1,
              status: :pass,
              marks_earned: 1,
              marks_total: 1,
              output: 'success',
              time: nil
            }
          end
          let(:tests) { [test1, test2, test3] }

          it 'should create a test_group_result with extra_info listing the errors of all failing tests' do
            expect(test_group_result.extra_info).to eq "test1 - Validation failed: Test Name has already been taken\n" \
                                                       'test1 - Validation failed: Test Name has already been taken'
          end

          context 'when stderr is set' do
            let(:stderr) { 'error' }

            it 'should create a test_group_result with extra_info including the messages on stderr and reasons for ' \
               'test failure' do
              expect(test_group_result.extra_info).to eq "Messages on stderr: \nerror\n\n" \
                                                         'test1 - Validation failed: ' \
                                                         "Test Name has already been taken\n" \
                                                         'test1 - Validation failed: Test Name has already been taken'
            end
          end
        end
      end

      context 'creating test results' do
        it 'should create 2 test group results' do
          expect { test_run.update_results!(results) }.to change { TestResult.count }.from(0).to(2)
        end

        it 'should associate the test results with the test group result' do
          test_run.update_results!(results)
          expect(TestResult.where(test_group_result: test_group_result).count).to eq 2
        end

        it 'should create a test_result with correct info' do
          test_run.update_results!(results)
          expect(TestResult.where(results['test_groups'].first['tests'].first)).not_to be_nil
        end

        it 'should create the other test_result with correct info' do
          test_run.update_results!(results)
          expect(TestResult.where(results['test_groups'].first['tests'].second)).not_to be_nil
        end

        it 'should remove null values from the output' do
          results['test_groups'].first['tests'].first['output'] = "abc\x00de"
          test_run.update_results!(results)
          expect(TestResult.where(output: 'abc\u0000de')).not_to be_nil
        end
      end

      context 'when it is associated with a submission' do
        let(:submission) { create(:version_used_submission, grouping: grouping) }
        let(:test_run) { create(:test_run, status: :in_progress, submission: submission) }

        it 'should create now criteria marks' do
          expect { test_run.update_results!(results) }.to(change { criterion.reload.marks })
        end

        it 'should set criteria marks' do
          criterion && assignment.ta_criteria.reload # Force ta_criterion to not be empty
          test_run.update_results!(results)
          expect(submission.results.first.get_total_mark).to eq 1
        end

        context 'when one of the tests produce an error' do
          let(:test2) { { name: :test1, status: :fail, marks_earned: 0, marks_total: 1, output: 'failure', time: nil } }
          let(:tests) { [test1, test2] }

          it 'should not affect the total mark' do
            criterion && assignment.ta_criteria.reload
            test_run.update_results!(results)
            expect(submission.results.first.get_total_mark).to eq 2
          end
        end
      end

      context 'when it is associated with a grouping' do
        it 'should not update criteria marks' do
          expect { test_run.update_results!(results) }.not_to(change { criterion.reload.marks.count })
        end
      end

      context 'when the results contain tags that don\'t exist' do
        it 'should create new tags and add them to the grouping' do
          results['test_groups'].first['tags'] =
            [{ 'name' => 'new_tag1', 'description' => 'd' }, { 'name' => 'new_tag2' }]
          expect { test_run.update_results!(results) }.to change { grouping.tags.count }.to eq 2
        end
      end

      context 'when the results contain tags that already exist' do
        it 'should add tags to the grouping without creating new ones' do
          results['test_groups'].first['tags'] = [existing_tag]
          expect { test_run.update_results!(results) }.not_to(change { Tag.count })
          expect(grouping.tags.count).to eq 1
        end
      end

      context 'when the results contain comments and has a submission without comments' do
        let(:submission) { create(:version_used_submission, grouping: grouping) }
        let(:test_run) { create(:test_run, submission: submission) }

        it 'should add comments to the submission\'s overall comments' do
          results['test_groups'].first['overall_comment'] = overall_comment1
          test_run.update_results!(results)
          expect(submission.current_result.overall_comment).to include(overall_comment1)
        end
      end

      context 'when the results contain comments and has a submission with an existing comment' do
        let(:result) do
          create(:result, marking_state: Result::MARKING_STATES[:complete], overall_comment: existing_comment)
        end
        let(:submission) { create(:version_used_submission, grouping: grouping, current_result: result) }
        let(:test_run) { create(:test_run, submission: submission) }

        it 'should append the comments without overwriting the existing comments' do
          results['test_groups'].first['overall_comment'] = overall_comment1
          test_run.update_results!(results)
          expect(submission.current_result.overall_comment).to include(overall_comment1)
          expect(submission.current_result.overall_comment).to include(existing_comment)
        end
      end

      context 'when the test run has a submission and the results contain an image annotation' do
        let(:submission) do
          create(:version_used_submission, grouping: grouping, submission_files: [submission_file_image])
        end
        let(:test_run) { create(:test_run, submission: submission) }

        it 'should add the image annotation to the submission' do
          results['test_groups'].first['annotations'] =
            [{ 'content' => 'test image annotation', 'type' => 'ImageAnnotation', 'filename' => 'test_compressed.png',
               'x1' => 0, 'y1' => 20, 'x2' => 10, 'y2' => 30 }]
          expect { test_run.update_results!(results) }.to change {
            submission.annotations.where(type: 'ImageAnnotation').count
          }.to eq 1
          expect(ImageAnnotation.first).to have_attributes(x1: 0, y1: 20, x2: 10, y2: 30)
          expect(ImageAnnotation.first.annotation_text.content).to eq('test image annotation')
          expect(ImageAnnotation.first.submission_file.filename).to eq('test_compressed.png')
        end
      end

      context 'when the test run has a submission and the results contain an annotation without a type' do
        let(:submission) do
          create(:version_used_submission, grouping: grouping, submission_files: [submission_file_text])
        end
        let(:test_run) { create(:test_run, submission: submission) }

        it 'should add the annotation to the submission as a text annotation' do
          results['test_groups'].first['annotations'] =
            [{ 'content' => 'test text annotation', 'filename' => 'test_compressed.txt', 'line_start' => 1,
               'line_end' => 2, 'column_start' => 0, 'column_end' => 4 }]
          expect { test_run.update_results!(results) }.to change {
            submission.annotations.where(type: 'TextAnnotation').count
          }.to eq 1
          expect(TextAnnotation.first).to have_attributes(line_start: 1, line_end: 2, column_start: 0, column_end: 4)
          expect(TextAnnotation.first.annotation_text.content).to eq('test text annotation')
          expect(TextAnnotation.first.submission_file.filename).to eq('test_compressed.txt')
        end
      end
    end
  end
end
