describe TestStudent do
  context 'A Test Student model' do
    it { is_expected.to validate_inclusion_of(:hidden).in_array([true]) }

    it 'will have many accepted groupings' do
      is_expected.to have_many(:accepted_groupings).through(:memberships)
    end

    it 'will have many student memberships' do
      is_expected.to have_many :student_memberships
    end
  end
  describe 'Creating the test student user' do
    context 'When the hidden field is not included' do
      let(:test_student) { TestStudent.create!(user_name: 'test', first_name: 'test', last_name: 'student') }
      it 'should raise an invalid record error' do
        expect { test_student }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
    context 'When the hidden field is false' do
      it 'should raise an invalid record error' do
        expect { create :test_student, hidden: false }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
    context 'When the hidden field is true' do
      let(:test_student) { create(:test_student, hidden: true) }
      it 'should not raise an invalid record error' do
        expect(test_student).to be_valid
      end
    end
  end
end
