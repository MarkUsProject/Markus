describe GroupPolicy do
  include PolicyHelper

  describe 'When the user is student' do
    subject { described_class.new(user: user) }
    let(:user) { build(:student) }
    it { is_expected.to pass :student_manage? }
    it { is_expected.not_to pass :manage? }
  end

  describe 'When the user is admin' do
    subject { described_class.new(user: user) }
    let(:user) { build(:admin) }
    it { is_expected.not_to pass :student_manage? }
    it { is_expected.to pass :manage? }
  end

  describe 'When the user is ta' do
    subject { described_class.new(user: user) }
    let(:user) { build(:ta) }
    it { is_expected.not_to pass :student_manage? }
    it { is_expected.not_to pass :manage? }
  end
end
