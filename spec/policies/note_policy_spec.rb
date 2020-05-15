describe NotePolicy do
  include PolicyHelper
  describe 'When the user is admin' do
    subject { described_class.new(user: user) }
    let(:user) { build(:admin) }
    context 'Admin can manage, create, edit and update the notes' do
      it { is_expected.to pass :manage? }
      it { is_expected.to pass :modify? }
      it { is_expected.to pass :create? }
    end
  end
  describe 'When the user is TA' do
    subject { described_class.new(note, user: user) }
    let(:user) { create(:ta) }
    let(:note) { create(:note) }
    context 'TA can manage the notes' do
      it { is_expected.to pass :manage? }
    end
    context 'When TA is editing or updating others note' do
      it { is_expected.not_to pass :modify? }
    end
    context 'When TA is editing or updating their own notes' do
      let(:note) { build(:note, user: user) }
      it { is_expected.to pass :modify? }
    end
    context 'When TA is allowed to create notes' do
      before do
        GraderPermission.create(user_id: user.id, create_notes: true)
      end
      it { is_expected.to pass :create? }
    end
    context 'When TA is not allowed to create notes' do
      before do
        GraderPermission.create(user_id: user.id, create_notes: false)
      end
      it { is_expected.not_to pass :create? }
    end
  end
end
