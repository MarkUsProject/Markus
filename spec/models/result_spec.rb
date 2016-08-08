require 'spec_helper'

describe Result do
  it { is_expected.to belong_to(:submission) }
  it { is_expected.to have_many(:marks) }
  it { is_expected.to have_many(:extra_marks) }
  it { is_expected.to have_many(:annotations) }
  it { is_expected.to validate_presence_of(:marking_state) }
  it { is_expected.to validate_inclusion_of(:marking_state).in_array(['complete', 'incomplete']) }
  it { is_expected.to validate_numericality_of(:total_mark).is_greater_than_or_equal_to(0) }
  it { is_expected.to callback(:create_marks).after(:create) }
  it { is_expected.to callback(:unrelease_partial_results).before(:update) }
  it { is_expected.to callback(:check_for_nil_marks).before(:save) }

  describe '.student_marks_by_assignment' do
    let(:assignment) { create(:assignment) }
    let!(:criteria) { Array.new(2) { create(:rubric_criterion, assignment: assignment) } }

    shared_examples 'empty' do
      it 'returns an empty array' do
        expect(Result.student_marks_by_assignment(assignment.id)).to be_empty
      end
    end

    context 'when no groupings are found' do
      it_returns 'empty'
    end

    # Since we are testing queries, the variables in this context need to be
    # eagerly created.
    context 'when groupings are found' do
      let!(:groupings) do
        Array.new(4) { create(:grouping, assignment: assignment) }
      end

      context 'when no students are found' do
        it_returns 'empty'
      end

      context 'when students are found' do
        let!(:students) { Array.new(4) { create(:student) } }

        context 'when no student memberships are found' do
          it_returns 'empty'
        end

        context 'when student memberships are found' do
          let!(:student_memberships) do
            # Leave the last grouping hanging to ensure the query is correct
            # with irelevant grouping.
            [
              create(:inviter_student_membership,
                     user: students.first,
                     grouping: groupings.first),
              create(:accepted_student_membership,
                     user: students.second,
                     grouping: groupings.first),
              create(:inviter_student_membership,
                     user: students.third,
                     grouping: groupings.second),
              create(:inviter_student_membership,
                     user: students.fourth,
                     grouping: groupings.third)
            ]
          end

          context 'when no submissions are found' do
            it_returns 'empty'
          end

          context 'when found submissions' do
            context 'with version not used only' do
              let!(:submission) do
                create(:submission, grouping: groupings.first)
              end

              context 'when a new result is created' do
                let!(:new_result) { submission.results.first }

                it 'has same amount of marks as criteria associated with the result' do
                  expect(new_result.marks.length).to eq(criteria.length)
                end

                it 'has a mark associated with each criterion' do
                  criteria.each do |criterion|
                    expect(criterion.marks.length).to be >= 1
                  end
                end
              end

              context 'when no results are found' do
                it_returns 'empty'
              end

              context 'when results are found' do
                let!(:results) do
                  create(:incomplete_result, submission: submission)
                end

                it_returns 'empty'
              end
            end

            context 'with version used only' do
              let!(:submissions) do
                Array.new(3) do |i|
                  create(:version_used_submission, grouping: groupings[i])
                end
              end

              context 'when a new result is created' do
                let!(:new_result) { submissions.first.results.first }

                it 'has same amount of marks as criteria associated with the result' do
                  expect(new_result.marks.length).to eq(criteria.length)
                end

                it 'has a mark associated with each criterion' do
                 criteria.each do |criterion|
                    expect(criterion.marks.length).to be >= 1
                 end
                end
              end

              context 'when no results are found' do
                it_returns 'empty'
              end

              context 'when an invalid marking state is found' do
                let!(:invalid_result) { create(:result, marking_state: Result::MARKING_STATES[:incomplete]) }
                before do
                  invalid_result.marking_state = 'wrong'
                end

                it 'considers the result invalid' do
                  expect(invalid_result.invalid?).to be true
                end
              end

              context 'when only incomplete results are found' do
                let!(:result) do
                  create(:incomplete_result, submission: submissions.first)
                  create(:incomplete_result, submission: submissions.second)
                end

                it_returns 'empty'
              end

              context 'when complete results are found' do
                let(:marks) { [3, 0, 9] }
                let!(:results) do
                  Array.new(3) do |i|
                    create(:result,
                           submission: submissions[i],
                           marking_state: Result::MARKING_STATES[:incomplete])
                  end
                end
                before do
                  results.each_with_index do |result, i|
                    result.marks.each do |m|
                      m.update(mark: 0.0)
                    end
                    result.total_mark = marks[i]
                    result.marking_state = Result::MARKING_STATES[:complete]
                    result.save
                  end
                end

                it 'returns a list of sorted student mark' do
                  # There are 2 students in one grouping with a mark of 3.
                  expect(Result.student_marks_by_assignment(assignment.id))
                    .to eq [0, 3, 3, 9]
                end

                context 'when a result is released' do
                  before do
                    results[1].update(released_to_students: true)
                  end

                  it 'considers the result valid' do
                    expect(results[1].valid?).to be true
                  end

                  it 'unreleases results' do
                    results[1].unrelease_results
                    expect(results[1].released_to_students).to be false
                  end
                end

                context 'when a result is marked as partial' do
                  before do
                    results[2].mark_as_partial
                  end

                  it 'is marked as incomplete' do
                    expect(results[2].marking_state).to eq(Result::MARKING_STATES[:incomplete])
                  end

                  context 'when marks are created for this incomplete result' do
                    let!(:incomp_result) { results[2] }
                    let!(:prev_subtotal) { incomp_result.get_subtotal }
                    let!(:flex_criteria_first) { create(:flexible_criterion, assignment: assignment) }
                    let!(:flex_criteria_second) { create(:flexible_criterion, max_mark: 2.0, assignment: assignment) }
                    before do
                      create(:flexible_mark, result: incomp_result, mark: 1, markable: flex_criteria_first)
                      create(:flexible_mark, result: incomp_result, mark: 2, markable: flex_criteria_second)
                    end

                    it 'gets a subtotal' do
                      expect(incomp_result.get_subtotal).to eq(prev_subtotal + 3)
                    end

                    it 'considers the result valid' do
                      expect(incomp_result.valid?).to be true
                    end
                  end
                end

                context 'when the first and third student become inactive' do
                  before do
                    [students.first, students.third].each do |student|
                      student.hidden = true
                      student.save
                    end
                  end

                  it 'returns a list excluding the first and third student' do
                    # There is still 1 active student in the first grouping.
                    expect(Result.student_marks_by_assignment(assignment.id))
                      .to eq [3, 9]
                  end
                end

                context 'when remarked results are found' do
                  let!(:remarked_result) do
                    # Create a new result for the second submission.
                    create(:result,
                           submission: submissions.second,
                           marking_state: Result::MARKING_STATES[:incomplete])
                  end
                  before do
                    remarked_result.marks.each do |m|
                      m.mark = 0.0
                      m.save
                    end
                    remarked_result.total_mark = 5
                    remarked_result.marking_state = Result::MARKING_STATES[:complete]
                    remarked_result.save
                  end

                  it 'returns student marks without old results' do
                    expect(Result.student_marks_by_assignment(assignment.id))
                      .to eq [3, 3, 5, 9]
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
