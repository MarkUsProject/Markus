describe NotePolicy do
  let(:context) { { role: role, real_user: role.user } }

  describe_rule :manage? do
    succeed 'role is instructor' do
      let(:role) { create(:instructor) }
    end
    succeed 'role is ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :modify? do
    succeed 'role is instructor' do
      let(:role) { create(:instructor) }
    end
    context 'role is ta' do
      let(:role) { create(:ta) }
      succeed 'role is the note creator' do
        let(:record) { create(:note, role: role) }
      end
      failed 'role is not the note creator' do
        let(:record) { create(:note) }
      end
    end
    context 'role is student' do
      let(:role) { create(:student) }
      succeed 'role is the note creator' do
        let(:record) { create(:note, role: role) }
      end
      failed 'role is not the note creator' do
        let(:record) { create(:note) }
      end
    end
  end
end
