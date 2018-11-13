describe UserPolicy do
  let(:policy) { described_class.new(user: user) }

  describe '#manage?' do
    subject { policy.apply(:manage?) }

    context 'when the user is admin' do
      let(:user) { Admin.new(user_name: 'admin', type: User::ADMIN) }
      it { is_expected.to eq true }
    end
    context 'when the user is ta' do
      let(:user) { Ta.new(user_name: 'ta', type: User::TA) }
      it { is_expected.to eq false }
    end
    context 'when the user is student' do
      let(:user) { Student.new(user_name: 'student', type: User::STUDENT) }
      it { is_expected.to eq false }
    end
  end

  describe '#destroy?' do
    subject { policy.apply(:destroy?) }

    context 'when the user is admin' do
      let(:user) { Admin.new(user_name: 'admin', type: User::ADMIN) }
      it { is_expected.to eq false }
    end
    context 'when the user is ta' do
      let(:user) { Ta.new(user_name: 'ta', type: User::TA) }
      it { is_expected.to eq false }
    end
    context 'when the user is student' do
      let(:user) { Student.new(user_name: 'student', type: User::STUDENT) }
      it { is_expected.to eq false }
    end
  end
end
