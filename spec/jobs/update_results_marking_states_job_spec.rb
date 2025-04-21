describe UpdateResultsMarkingStatesJob do
  let!(:assignment) { create(:assignment_with_criteria_and_results) }
  let(:assignment_id) { assignment.id }
  let(:status) { :incomplete }

  context 'when running as a background job' do
    let(:job_args) { [assignment_id, status] }

    it_behaves_like 'background job'
  end

  context 'when not running as a background job' do
    let(:job) { UpdateResultsMarkingStatesJob.perform_now(assignment_id, status) }
    let(:results) { Result.includes(submission: :grouping).where(groupings: { assessment_id: assignment.id }) }

    context 'when all results are complete' do
      it 'should update results to incomplete when incomplete is an argument' do
        expect { job }.to change { results.reload.pluck(:marking_state) }.from(['complete'] * 3).to(['incomplete'] * 3)
      end

      context 'when complete is an argument' do
        let(:status) { :complete }

        it 'should not update results' do
          expect { job }.not_to(change { results.reload.pluck(:marking_state) })
        end
      end
    end

    context 'when some results are complete' do
      before { Result.first.update!(marking_state: Result::MARKING_STATES[:incomplete]) }

      it 'should update results to incomplete when incomplete is an argument' do
        expect { job }.to change { results.reload.pluck(:marking_state).count('incomplete') }.from(1).to(3)
      end

      context 'when complete is an argument' do
        let(:status) { :complete }

        it 'should not update results' do
          expect { job }.to change { results.reload.pluck(:marking_state).count('complete') }.from(2).to(3)
        end
      end
    end

    context 'where there are results for a different assignment' do
      let!(:assignment2) { create(:assignment_with_criteria_and_results) }
      let(:assignment_id) { assignment2.id }
      let(:results) { Result.includes(submission: :grouping).where(groupings: { assessment_id: assignment.id }) }

      it 'should not update results' do
        expect { job }.not_to(change { results.reload.pluck(:marking_state) })
      end
    end
  end
end
