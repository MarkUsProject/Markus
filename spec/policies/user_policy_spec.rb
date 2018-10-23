describe UserPolicy do
  let(:admin) { Admin.new(user_name: 'admin', type: User::ADMIN) }
  let(:ta) { Ta.new(user_name: 'ta', type: User::TA) }
  let(:student) { Student.new(user_name: 'student', type: User::STUDENT) }

  subject { described_class }

  permissions :create? do
    it 'allows admins to create users' do
      expect(subject).to permit(admin, User)
    end
    it 'forbids tas to create users' do
      expect(subject).not_to permit(ta, User)
    end
    it 'forbids students to create users' do
      expect(subject).not_to permit(student, User)
    end
  end

  permissions :update? do
    it 'allows admins to update users' do
      expect(subject).to permit(admin, User)
    end
    it 'forbids tas to update users' do
      expect(subject).not_to permit(ta, User)
    end
    it 'forbids students to update users' do
      expect(subject).not_to permit(student, User)
    end
  end
end
