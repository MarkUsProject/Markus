describe NotePolicy do
  include PolicyHelper
  describe 'When the user is admin' do
    subject { described_class.new(user: user) }
    let(:user) { build(:admin) }
    context 'Admin can manage, edit and update the notes' do
      it { is_expected.to pass :manage? }
      it { is_expected.to pass :edit? }
      it { is_expected.to pass :update? }
    end
  end
  describe 'When the user is TA' do
    subject { described_class.new(note, user: user) }
    let(:user) { build(:ta) }
    let(:note) {create(:note)}
    context 'TA can manage the notes' do
      it { is_expected.to pass :manage? }
    end
    context 'When TA is editing or updating others note' do
      it { is_expected.not_to pass :edit?, because_of: :ensure_can_modify? }
      it { is_expected.not_to pass :update?, because_of: :ensure_can_modify? }
    end
    context 'When TA is editing or updating their own notes' do
      let(:note) {build(:note, user: user)}
      it { is_expected.to pass :edit? }
      it { is_expected.to pass :update? }
    end
  end
end

