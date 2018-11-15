describe UserPolicy do
  let(:policy) { described_class.new(user: user) }

  describe '#manage?' do
    subject { policy.apply(:manage?) }

    context 'when the user is admin' do
      let(:user) { build(:admin) }
      it { is_expected.to eq true }
    end
    context 'when the user is ta' do
      let(:user) { build(:ta) }
      it { is_expected.to eq false }
    end
    context 'when the user is student' do
      let(:user) { build(:student) }
      it { is_expected.to eq false }
    end
  end

  describe '#destroy?' do
    subject { policy.apply(:destroy?) }

    context 'when the user is admin' do
      let(:user) { build(:admin) }
      it { is_expected.to eq false }
    end
    context 'when the user is ta' do
      let(:user) { build(:ta) }
      it { is_expected.to eq false }
    end
    context 'when the user is student' do
      let(:user) { build(:student) }
      it { is_expected.to eq false }
    end
  end
end
