describe CheckboxCriterion do
  let(:criterion_factory_name) { :checkbox_criterion }

  context 'A good Checkbox Criterion model' do
    before :each do
      @criterion = create(:checkbox_criterion)
    end

    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:max_mark) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:assignment_id) }
    it { is_expected.to validate_numericality_of(:max_mark) }
  end

  context 'validations work properly' do
    before(:each) do
      @criterion = create(:checkbox_criterion)
    end

    context 'when a result is released' do
      before(:each) do
        @marks = @criterion.marks
        results = []
        3.times do
          results << create(:complete_result, released_to_students: false)
        end
        @marks.create(mark: 0, result: results[0])
        @marks.create(mark: 1, result: results[1])
        @marks.create(mark: 1, result: results[2])
        results.each do |result|
          # have to release to students after or else cannot assign marks
          result.released_to_students = true
          result.save
        end
      end

      describe 'checkbox criteria can\'t be updated' do
        it 'not raise error' do
          expect(@criterion.update(max_mark: 10)).to be false
        end
      end
    end
  end
end
