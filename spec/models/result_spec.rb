describe Result do
  let!(:assignment) { create(:assignment_with_criteria_and_results) }

  describe 'callbacks and validations' do
    let(:result) { assignment.current_results.first }
    let(:assignment) { create(:assignment_with_criteria_and_results) }

    it { is_expected.to belong_to(:submission) }
    it { is_expected.to have_many(:marks) }
    it { is_expected.to have_many(:extra_marks) }
    it { is_expected.to have_many(:annotations) }
    it { is_expected.to validate_presence_of(:marking_state) }
    it { is_expected.to validate_inclusion_of(:marking_state).in_array(%w[complete incomplete]) }
    it { is_expected.to callback(:create_marks).after(:create) }
    it { is_expected.to callback(:check_for_released).before(:update) }
    it { is_expected.to callback(:check_for_nil_marks).before(:save) }
    it { is_expected.to have_one(:course) }

    context 'check_for_nil_marks' do
      context 'when the result is complete' do
        context 'updating the marking state' do
          it 'should not raise a validation error' do
            expect { result.update!(marking_state: Result::MARKING_STATES[:complete]) }.not_to raise_error
          end
        end

        context 'updating something else (view_token)' do
          it 'should not raise a validation error' do
            expect { result.regenerate_view_token }.not_to raise_error
          end
        end
      end

      context 'when the result is incomplete' do
        before { result.update!(marking_state: Result::MARKING_STATES[:incomplete]) }

        context 'when all criteria have marks' do
          context 'updating the marking state' do
            it 'should not raise a validation error' do
              expect { result.update!(marking_state: Result::MARKING_STATES[:complete]) }.not_to raise_error
            end
          end

          context 'updating something else (view_token)' do
            it 'should not raise a validation error' do
              expect { result.regenerate_view_token }.not_to raise_error
            end
          end
        end

        context 'when some criteria do not have marks' do
          before { result.marks.first.destroy }

          context 'updating the marking state' do
            it 'should raise a validation error' do
              expect do
                result.update!(marking_state: Result::MARKING_STATES[:complete])
              end.to raise_error(ActiveRecord::RecordNotSaved)
            end
          end

          context 'updating something else (view_token)' do
            it 'should not raise a validation error' do
              expect { result.regenerate_view_token }.not_to raise_error
            end
          end
        end
      end
    end
  end

  shared_context 'get subtotal context' do
    let(:result) { create(:incomplete_result) }
    let(:assignment) { result.submission.grouping.assignment }
    let(:criterion) { create(:flexible_criterion, assignment: assignment, max_mark: 10) }
    let(:criterion2) { create(:flexible_criterion, assignment: assignment, max_mark: 10) }

    before do
      create(:flexible_mark, criterion: criterion, result: result, mark: 5)
      create(:flexible_mark, criterion: criterion2, result: result, mark: 7)
    end
  end

  shared_examples 'get subtotal only' do |method_name|
    context 'there are no extra marks' do
      it 'should return the subtotal' do
        expect(result.public_send(method_name)).to eq 12
      end
    end

    context 'one criterion is peer_visible only' do
      let(:criterion) do
        create(:flexible_criterion,
               assignment: result.submission.grouping.assignment,
               max_mark: 10,
               ta_visible: false,
               peer_visible: true)
      end

      context 'the result is a review' do
        before { allow(result).to receive(:is_a_review?).and_return(true) }

        it 'should return a subtotal of the peer_visible marks' do
          expect(result.public_send(method_name)).to eq 5
        end
      end

      context 'the result is not a review' do
        before { allow(result).to receive(:is_a_review?).and_return(false) }

        it 'should return a subtotal of the peer_visible marks' do
          expect(result.public_send(method_name)).to eq 7
        end
      end
    end
  end

  shared_examples 'get subtotals only' do |method_name|
    context 'there are no extra marks' do
      it 'should return a hash containing the subtotal for each result' do
        ids = Result.ids
        expected = ids.index_with do |id|
          Result.find(id).marks.pluck(:mark).sum
        end
        expect(Result.public_send(method_name, ids)).to eq expected
      end
    end

    context 'some criteria are peer_visible only' do
      before { assignment.criteria.first.update!(ta_visible: false, peer_visible: true) }

      context 'user_visibility is set to ta_visible' do
        it 'should only return subtotals that are ta_visible' do
          ids = Result.ids
          expected = ids.index_with do |id|
            Result.find(id).marks.joins(:criterion).where('criteria.ta_visible': true).pluck(:mark).sum
          end
          expect(Result.public_send(method_name, ids, user_visibility: :ta_visible)).to eq expected
        end
      end

      context 'user_visibility is set to peer_visible' do
        it 'should only return subtotals that are peer_visible' do
          ids = Result.ids
          expected = ids.index_with do |id|
            Result.find(id).marks.joins(:criterion).where('criteria.peer_visible': true).pluck(:mark).sum
          end
          expect(Result.public_send(method_name, ids, user_visibility: :peer_visible)).to eq expected
        end
      end
    end
  end

  describe '.get_total_extra_marks' do
    before { create(:assignment_with_criteria_and_results) }

    context 'there are no extra marks' do
      it 'should return an empty hash' do
        ids = Result.ids
        expected = Hash.new { |h, k| h[k] = nil }
        expect(Result.get_total_extra_marks(ids)).to eq(expected)
      end
    end

    context 'there are only one zero extra mark' do
      it 'should return a hash containing only one zero extra mark' do
        ids = Result.ids
        extra_mark = 0.0
        create(:extra_mark_points, result: Result.find(ids.first), extra_mark: extra_mark)
        expected = Hash.new { |h, k| h[k] = nil }
        expected[ids.first] = extra_mark
        expect(Result.get_total_extra_marks(ids)).to eq(expected)
      end
    end

    context 'with percentage_of_score extra marks' do
      it 'should calculate extra marks based on percentage of earned score' do
        ids = Result.ids
        result = Result.find(ids.first)
        subtotal = result.get_subtotal
        extra_mark = 5.0

        create(:extra_mark_percentage_of_score, result: result, extra_mark: extra_mark)
        expected = Hash.new { |h, k| h[k] = nil }
        expected[ids.first] = (extra_mark * subtotal / 100).round(2)
        expect(Result.get_total_extra_marks(ids)).to eq(expected)
      end

      it 'should handle zero subtotal when calculating percentage of score' do
        ids = Result.ids
        result = Result.find(ids.first)
        result.marks.update_all(mark: 0)
        extra_mark = 10.0

        create(:extra_mark_percentage_of_score, result: result, extra_mark: extra_mark)
        expected = Hash.new { |h, k| h[k] = nil }
        expected[ids.first] = 0.0
        expect(Result.get_total_extra_marks(ids)).to eq(expected)
      end

      it 'should calculate extra marks based on percentage of earned score with negative deduction' do
        ids = Result.ids
        result = Result.find(ids.first)
        subtotal = result.get_subtotal
        extra_mark = -5.0

        create(:extra_mark_percentage_of_score, result: result, extra_mark: extra_mark)
        expected = Hash.new { |h, k| h[k] = nil }
        expected[ids.first] = (extra_mark * subtotal / 100).round(2)
        expect(Result.get_total_extra_marks(ids)).to eq(expected)
      end

      it 'should round to 2 decimal places' do
        ids = Result.ids
        result = Result.find(ids.first)
        subtotal = result.get_subtotal
        extra_mark = 7.0

        create(:extra_mark_percentage_of_score, result: result, extra_mark: extra_mark)
        actual = Result.get_total_extra_marks(ids)[ids.first]
        expect(actual).to eq(actual.round(2))

        expected = (extra_mark * subtotal / 100).round(2)
        expect(actual).to eq(expected)
      end
    end
  end

  describe '#get_total_mark' do
    include_context 'get subtotal context'
    it_behaves_like 'get subtotal only', :get_total_mark
    context 'extra marks exist' do
      it 'should return the subtotal plus the extra mark' do
        create(:extra_mark, result: result, extra_mark: 10)
        expect(result.reload.get_total_mark).to eq 14
      end
    end
  end

  describe '.get_total_marks' do
    it_behaves_like 'get subtotals only', :get_total_marks
    context 'there are some extra marks' do
      it 'should return a hash containing the subtotal plus the extra mark for each result' do
        ids = Result.ids
        create(:extra_mark_points, result: Result.find(ids.first), extra_mark: 2)
        expected = ids.index_with { |id| Result.find(id).marks.pluck(:mark).sum }
        expected[ids.first] += 2
        expect(Result.get_total_marks(ids)).to eq(expected)
      end
    end
  end

  describe '#get_subtotal' do
    include_context 'get subtotal context'
    it_behaves_like 'get subtotal only', :get_subtotal
    context 'extra marks exist' do
      it 'should return the subtotal' do
        create(:extra_mark, result: result)
        expect(result.reload.get_subtotal).to eq 12
      end
    end
  end

  describe '.get_subtotals' do
    it_behaves_like 'get subtotals only', :get_subtotals
    context 'there are some extra marks' do
      it 'should return a hash containing the subtotal for each result' do
        ids = Result.ids
        create(:extra_mark, result: Result.find(ids.first))
        expect(Result.get_subtotals(ids)).to eq(ids.index_with { |id| Result.find(id).marks.pluck(:mark).sum })
      end
    end
  end

  describe '#view_token_expired?' do
    subject { result.view_token_expired? }

    let(:result) { create(:complete_result, view_token_expiry: expiry) }

    context 'no view token expiry exists for the result' do
      let(:expiry) { nil }

      it { is_expected.to be_falsy }
    end

    context 'a view token expiry exists' do
      context 'and it is in the future' do
        let(:expiry) { 1.day.from_now }

        it { is_expected.to be_falsy }
      end

      context 'and it is in the past' do
        let(:expiry) { 1.day.ago }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '.set_release_on_results' do
    let(:assignment) { create(:assignment_with_criteria_and_results) }

    it 'should raise StandardError with message not_complete error if result has not been completed' do
      result = assignment.current_results.first
      result.submission.make_remark_result
      group_names = result.grouping.group_name_with_student_user_names[0..5] # Get only group name, not student
      expect { Result.set_release_on_results(assignment.groupings, true) }
        .to raise_error(I18n.t('submissions.errors.not_complete', group_name: group_names))
    end

    it 'should raise StandardError with message not_complete_unrelease error if result has not been completed' do
      result = assignment.current_results.first
      result.submission.make_remark_result
      group_names = result.grouping.group_name_with_student_user_names[0..5] # Get only group name, not student
      expect { Result.set_release_on_results(assignment.groupings, false) }
        .to raise_error(I18n.t('submissions.errors.not_complete_unrelease', group_name: group_names))
    end

    it 'should raise a StandardError with message no_submission error if the grouping does not have a submission' do
      grouping = create(:grouping)
      expect { Result.set_release_on_results(assignment.groupings.concat(grouping), true) }
        .to raise_error(I18n.t('submissions.errors.no_submission', group_name:
          grouping.group_name_with_student_user_names))
    end

    it 'should release submissions' do
      Result.set_release_on_results(assignment.groupings, true)
      result = assignment.current_results.first
      expect(result.released_to_students).to be(true)
    end

    it 'should unrelease a released submission' do
      Result.set_release_on_results(assignment.groupings, true)
      Result.set_release_on_results(assignment.groupings, false)
      result = assignment.current_results.first
      expect(result.released_to_students).to be(false)
    end
  end

  describe '#generate_print_pdf' do
    let(:assignment) { create(:assignment_with_criteria_and_results) }
    let(:result) { assignment.current_results.first }

    context 'when the result has marks and no PDF submission files' do
      it 'successfully creates a PDF' do
        pdf_file = result.generate_print_pdf
        expect(pdf_file).to be_a CombinePDF::PDF
      end
    end

    context 'when the result has no marks and no PDF submission files' do
      let(:grouping) { create(:grouping, assignment: assignment) }
      let(:submission) { create(:submission, grouping: grouping) }
      let(:result) { create(:incomplete_result, submission: submission) }

      it 'successfully creates a PDF' do
        pdf_file = result.generate_print_pdf
        expect(pdf_file).to be_a CombinePDF::PDF
      end
    end

    context 'when the result has a PDF submission file' do
      let!(:submission_file) { create(:pdf_submission_file, submission: result.submission) }

      before do
        allow_any_instance_of(SubmissionFile).to receive(:retrieve_file).and_return(
          file_fixture('submission_files/pdf.pdf').read
        )
      end

      it 'successfully creates a PDF' do
        pdf_file = result.generate_print_pdf
        expect(pdf_file).to be_a CombinePDF::PDF
      end

      context 'when the result also has annotations' do
        before { create(:pdf_annotation, result: result, submission_file: submission_file) }

        it 'successfully creates a PDF' do
          pdf_file = result.generate_print_pdf
          expect(pdf_file).to be_a CombinePDF::PDF
        end
      end
    end

    context 'when the result has a Jupyter notebook submission file' do
      before do
        create(:notebook_submission_file, submission: result.submission)
        allow_any_instance_of(SubmissionFile).to receive(:retrieve_file).and_return(
          file_fixture('submission_files/submission.ipynb').read
        )
      end

      it 'successfully creates a PDF' do
        pdf_file = result.generate_print_pdf
        expect(pdf_file).to be_a CombinePDF::PDF
      end

      context 'when nbconvert fails' do
        before do
          allow(Open3).to receive(:capture3).and_return(['', '', instance_double(Process::Status, success?: false)])
        end

        it 'raises an error' do
          expect { result.generate_print_pdf }.to raise_error(RuntimeError)
        end
      end
    end

    context 'when the result has extra marks' do
      before { create(:extra_mark, result: result) }

      it 'successfully creates a PDF' do
        pdf_file = result.generate_print_pdf
        expect(pdf_file).to be_a CombinePDF::PDF
      end
    end

    context 'whe the result has an overall comment' do
      before do
        result.update(overall_comment: 'My comment')
      end

      it 'successfully creates a PDF' do
        pdf_file = result.generate_print_pdf
        expect(pdf_file).to be_a CombinePDF::PDF
      end
    end

    context 'when the assignment has rubric criteria' do
      before do
        assignment.current_results.each(&:mark_as_partial)
        create(:rubric_criterion, assignment: assignment)
      end

      it 'successfully creates a PDF' do
        expect(assignment.ta_criteria.size).to eq 4
        pdf_file = result.generate_print_pdf
        expect(pdf_file).to be_a CombinePDF::PDF
      end
    end
  end

  describe '#print_pdf_filename' do
    let(:assignment) { create(:assignment_with_criteria_and_results) }
    let(:result) { assignment.current_results.first }

    context 'when the result is for an individual student' do
      it 'returns a filename containing data for the student' do
        student = result.submission.grouping.accepted_students.first.user
        expect(result.print_pdf_filename).to eq(
          "#{student.id_number} - #{student.last_name.upcase}, #{student.first_name} (#{student.user_name}).pdf"
        )
      end
    end

    context 'when the result is for a group with multiple members' do
      it 'returns a filename corresponding to the group name and member user names' do
        grouping = result.submission.grouping
        create(:accepted_student_membership, grouping: grouping)
        members = grouping.accepted_students.includes(:user).map { |s| s.user.user_name }.sort
        expect(result.print_pdf_filename).to eq "#{grouping.group.group_name} (#{members.join(', ')}).pdf"
      end
    end

    context 'when the result is for a group with no members' do
      it 'returns a filename corresponding to the group name' do
        grouping = result.submission.grouping
        grouping.student_memberships.destroy_all
        expect(result.print_pdf_filename).to eq "#{grouping.group.group_name}.pdf"
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

      @new_result = @new_submission.reload.current_result
      @new_result.copy_grading_data(@original_result)
      @new_result.reload
    end

    context 'for overall comment on the new result' do
      before do
        @original_result.update(overall_comment: 'Sample overall comment')
        @new_submission = create(:submission,
                                 grouping: @original_submission.grouping)
        @new_result = @new_submission.current_result
        @new_result.copy_grading_data(@original_result)
        @new_result.reload
      end

      it 'retains overall_comment' do
        expect(@new_result.overall_comment).to eq(@original_result.overall_comment)
      end
    end

    context 'for remark data on the new result' do
      let(:assignment) { create(:assignment_with_criteria_and_results_with_remark) }

      it 'retains remark_request_submitted_at' do
        expect(@new_result.remark_request_submitted_at).to eq(@original_result.remark_request_submitted_at)
      end
    end

    context 'for marks on the new result' do
      it 'creates the correct number of new marks' do
        expect(@new_result.reload.marks.size).to eq(@original_result.marks.size)
        expect(@new_result.marks.ids.sort).not_to eq(@original_result.marks.ids.sort)
      end

      it 'retains the correct mark values' do
        expect(@new_result.marks.order(:criterion_id).map(&:mark)).to eq(@original_result
          .marks.order(:criterion_id).map(&:mark))
      end
    end

    context 'for annotations on the new result' do
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
          @new_result = @new_submission.current_result
          @new_result.copy_grading_data(@original_result)
          @new_result.reload
        end

        it 'does not retain any annotations' do
          expect(@new_result.annotations).to be_empty
        end
      end
    end

    context 'for extra marks on the new result' do
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
