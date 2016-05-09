require 'spec_helper'

describe Result do
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
