describe UserPolicy do
  include PolicyHelper

  describe '#manage?' do
    subject { described_class.new(user: user) }

    context 'when the user is admin' do
      let(:user) { build(:admin) }
      it { is_expected.to pass :manage? }
    end
    context 'when the user is ta' do
      let(:user) { build(:ta) }
      it { is_expected.not_to pass :manage? }
    end
    context 'when the user is student' do
      let(:user) { build(:student) }
      it { is_expected.not_to pass :manage? }
    end
  end

  describe '#destroy?' do
    subject { described_class.new(user: user) }

    context 'when the user is admin' do
      let(:user) { build(:admin) }
      it { is_expected.not_to pass :destroy? }
    end
    context 'when the user is ta' do
      let(:user) { build(:ta) }
      it { is_expected.not_to pass :destroy? }
    end
    context 'when the user is student' do
      let(:user) { build(:student) }
      it { is_expected.not_to pass :destroy? }
    end
  end
end
