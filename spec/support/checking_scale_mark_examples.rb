shared_examples 'Scale_mark' do
  describe 'when update is true' do
    describe 'when mark is nil' do
      before do
        mark.update(mark: nil)
      end

      it 'should return nil' do
        expect(mark.scale_mark(curr_max_mark, mark.criterion.max_mark)).to be_nil
      end

      it 'should not update the mark' do
        expect(mark.mark).to be_nil
      end
    end

    describe 'when mark is 0 or prev_max_mark is 0' do
      before do
        mark.update(mark: 0)
      end

      it 'should return 0' do
        expect(mark.scale_mark(curr_max_mark, mark.criterion.max_mark)).to eq(0)
        expect(mark.scale_mark(curr_max_mark, 0)).to eq(0)
      end

      it 'should not update the mark' do
        expect(mark.mark).to eq(0)
      end
    end

    it 'should update and return the new_mark' do
      expect(mark.scale_mark(curr_max_mark, mark.criterion.max_mark)).to eq(mark.mark)
    end
  end

  describe 'when update is false' do
    it 'should not update the new mark' do
      expect(mark.scale_mark(curr_max_mark, mark.criterion.max_mark, update: false)).not_to eq(mark.mark)
    end
  end
end
