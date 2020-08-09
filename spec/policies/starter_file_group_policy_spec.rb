describe StarterFileGroupPolicy do
  include PolicyHelper
  describe 'When the user is admin' do
    subject { described_class.new(user: user) }
    let(:user) { build(:admin) }
    context 'can access the starter file groups' do
      it { is_expected.to pass :manage? }
    end
  end
  describe 'When the user is grader' do
    subject { described_class.new(user: user) }
    let(:user) { build(:ta) }
    context 'cannot access the starter file groups' do
      it { is_expected.not_to pass :manage? }
    end
  end
  describe 'When the user is student' do
    subject { described_class.new(user: user) }
    let(:user) { build(:student) }
    context 'cannot access the starter file groups' do
      it { is_expected.not_to pass :manage? }
    end
  end
end
