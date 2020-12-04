describe NotePolicy do
  let(:context) { { user: user } }

  describe_rule :manage? do
    succeed 'user is admin' do
      let(:user) { create :admin }
    end
    succeed 'user is ta' do
      let(:user) { create :ta }
    end
    failed 'user is student' do
      let(:user) { create :student }
    end
  end

  describe_rule :modify? do
    succeed 'user is admin' do
      let(:user) { create :admin }
    end
    context 'user is ta' do
      let(:user) { create :ta }
      succeed 'user is the note creator' do
        let(:record) { create :note, user: user }
      end
      failed 'user is not the note creator' do
        let(:record) { create :note }
      end
    end
    context 'user is student' do
      let(:user) { create :student }
      succeed 'user is the note creator' do
        let(:record) { create :note, user: user }
      end
      failed 'user is not the note creator' do
        let(:record) { create :note }
      end
    end
  end
end
