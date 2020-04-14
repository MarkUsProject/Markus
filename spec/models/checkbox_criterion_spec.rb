describe CheckboxCriterion do
  let(:criterion_factory_name) { :flexible_criterion }

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

      describe 'flexible criteria can\'t be updated' do
        it 'not raise error' do
          expect(@criterion.update(max_mark: 10)).to be false
        end
      end
    end
  end

end