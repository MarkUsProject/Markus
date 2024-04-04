describe Extension do
  let(:grouping) { create(:grouping) }
  let(:extension) { create(:extension, grouping: grouping) }
  it { is_expected.to belong_to(:grouping) }
  it { is_expected.to have_one(:course) }
  describe 'check validations' do
    it 'should not be valid with a negative time_delta' do
      extension = Extension.new(grouping_id: grouping, time_delta: -1.day)
      expect(extension.valid?).to be(false)
    end
    it 'should be valid with a positive time_delta' do
      extension = Extension.new(grouping: grouping, time_delta: 1.day)
      expect(extension.valid?).to be(true)
    end
  end
  describe 'check callbacks' do
    it 'should mark the group as instructor approved on creation' do
      create(:student_membership, grouping: grouping)
      expect { extension }.to change { grouping.instructor_approved }.to(true)
    end
  end
  describe '#to_parts' do
    it 'should return the time_delta attribute calculated as PARTS' do
      time_delta = extension.time_delta
      parts = extension.to_parts
      duration_from_parts = Extension::PARTS.sum { |part| parts[part].to_i.public_send(part) }
      expect(time_delta).to eq(duration_from_parts)
    end
    it 'should return only the parts in PARTS' do
      expect(extension.to_parts.keys).to contain_exactly(*Extension::PARTS)
    end
  end
  describe '.to_parts' do
    let(:duration) { Extension::PARTS.sum { |part| rand(1..10).public_send(part) } }
    it 'should return the duration calculated as PARTS' do
      parts = Extension.to_parts duration
      duration_from_parts = Extension::PARTS.sum { |part| parts[part].to_i.public_send(part) }
      expect(duration).to eq(duration_from_parts)
    end
    it 'should return only the parts in PARTS' do
      expect(Extension.to_parts(duration).keys).to contain_exactly(*Extension::PARTS)
    end
  end
end
