describe Result do
  it { is_expected.to belong_to(:submission) }
  it { is_expected.to have_many(:marks) }
  it { is_expected.to have_many(:extra_marks) }
  it { is_expected.to have_many(:annotations) }
  it { is_expected.to validate_presence_of(:marking_state) }
  it { is_expected.to validate_inclusion_of(:marking_state).in_array(['complete', 'incomplete']) }
  it { is_expected.to validate_numericality_of(:total_mark).is_greater_than_or_equal_to(0) }
  it { is_expected.to callback(:create_marks).after(:create) }
  it { is_expected.to callback(:check_for_released).before(:update) }
  it { is_expected.to callback(:check_for_nil_marks).before(:save) }

  shared_context 'get subtotals context' do
    let!(:assignment) { create :assignment_with_criteria_and_results }
  end
  describe '#update_total_mark' do
    let(:result) { create :incomplete_result }
    it 'should update the total mark' do
      old_total = result.total_mark
      allow(result).to receive(:get_total_mark).and_return(old_total - 1)
      expect { result.update_total_mark }.to change { result.total_mark }.by(-1)
    end
  end
  describe '.update_total_marks' do
    include_context 'get subtotals context'
    it 'should update all total_marks' do
      ids = Result.ids
      changes = ids.map { |id| [id, Result.find(id).total_mark - 1] }.to_h
      allow(Result).to receive(:get_total_marks).and_return(changes)
      expect { Result.update_total_marks(ids) }.to(
        change { Result.pluck(:total_mark) }.to(contain_exactly(*changes.values))
      )
    end
  end
  shared_context 'get subtotal context' do
    let(:result) { create :incomplete_result }
    let(:criterion) { create :flexible_criterion, assignment: result.submission.grouping.assignment, max_mark: 10 }
    let(:criterion2) { create :flexible_criterion, assignment: result.submission.grouping.assignment, max_mark: 10 }
    let!(:mark) { create :flexible_mark, criterion: criterion, result: result, mark: 5 }
    let!(:mark2) { create :flexible_mark, criterion: criterion2, result: result, mark: 7 }
  end
  shared_examples 'get subtotal only' do |method_name|
    context 'there are no extra marks' do
      it 'should return the subtotal' do
        expect(result.send(method_name)).to eq 12
      end
    end
    context 'one criterion is peer_visible only' do
      let(:criterion) do
        create :flexible_criterion,
               assignment: result.submission.grouping.assignment,
               max_mark: 10,
               ta_visible: false,
               peer_visible: true
      end
      context 'the result is a review' do
        before { allow(result).to receive(:is_a_review?).and_return(true) }
        it 'should return a subtotal of the peer_visible marks' do
          expect(result.send(method_name)).to eq 5
        end
      end
      context 'the result is not a review' do
        before { allow(result).to receive(:is_a_review?).and_return(false) }
        it 'should return a subtotal of the peer_visible marks' do
          expect(result.send(method_name)).to eq 7
        end
      end
    end
  end
  shared_examples 'get subtotals only' do |method_name|
    context 'there are no extra marks' do
      it 'should return a hash containing the subtotal for each result' do
        ids = Result.pluck(:id)
        expect(Result.send(method_name, ids)).to eq(ids.map { |id| [id, Result.find(id).marks.pluck(:mark).sum] }.to_h)
      end
    end
    context 'some criteria are peer_visible only' do
      before { assignment.criteria.first.update!(ta_visible: false, peer_visible: true) }
      context 'user_visibility is set to ta_visible' do
        it 'should only return subtotals that are ta_visible' do
          ids = Result.pluck(:id)
          expected = ids.map do |id|
            [id, Result.find(id).marks.joins(:criterion).where('criteria.ta_visible': true).pluck(:mark).sum]
          end.to_h
          expect(Result.send(method_name, ids, user_visibility: :ta_visible)).to eq expected
        end
      end
      context 'user_visibility is set to peer_visible' do
        it 'should only return subtotals that are peer_visible' do
          ids = Result.pluck(:id)
          expected = ids.map do |id|
            [id, Result.find(id).marks.joins(:criterion).where('criteria.peer_visible': true).pluck(:mark).sum]
          end.to_h
          expect(Result.send(method_name, ids, user_visibility: :peer_visible)).to eq expected
        end
      end
    end
  end
  describe '#get_total_mark' do
    include_context 'get subtotal context'
    include_examples 'get subtotal only', :get_total_mark
    context 'extra marks exist' do
      it 'should return the subtotal plus the extra mark' do
        create(:extra_mark, result: result, extra_mark: 10)
        expect(result.reload.get_total_mark).to eq 14
      end
    end
  end
  describe '.get_total_marks' do
    include_context 'get subtotals context'
    include_examples 'get subtotals only', :get_total_marks
    context 'there are some extra marks' do
      it 'should return a hash containing the subtotal plus the extra mark for each result' do
        ids = Result.pluck(:id)
        create(:extra_mark_points, result: Result.find(ids.first), extra_mark: 2)
        expected = ids.map { |id| [id, Result.find(id).marks.pluck(:mark).sum] }.to_h
        expected[ids.first] += 2
        expect(Result.get_total_marks(ids)).to eq(expected)
      end
    end
  end
  describe '#get_subtotal' do
    include_context 'get subtotal context'
    include_examples 'get subtotal only', :get_subtotal
    context 'extra marks exist' do
      it 'should return the subtotal' do
        create(:extra_mark, result: result)
        expect(result.reload.get_subtotal).to eq 12
      end
    end
  end
  describe '.get_subtotals' do
    include_context 'get subtotals context'
    include_examples 'get subtotals only', :get_subtotals
    context 'there are some extra marks' do
      it 'should return a hash containing the subtotal for each result' do
        ids = Result.pluck(:id)
        create(:extra_mark, result: Result.find(ids.first))
        expect(Result.get_subtotals(ids)).to eq(ids.map { |id| [id, Result.find(id).marks.pluck(:mark).sum] }.to_h)
      end
    end
  end
end
