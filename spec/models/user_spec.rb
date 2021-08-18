require 'rails_helper'

describe User do
  it { is_expected.to have_many :memberships }
  it { is_expected.to have_many(:groupings).through(:memberships) }
  it { is_expected.to have_many(:notes).dependent(:destroy) }
  it { is_expected.to have_many :accepted_memberships }
  it { is_expected.to have_many(:key_pairs).dependent(:destroy) }
  it { is_expected.to validate_presence_of :user_name }
  it { is_expected.to validate_presence_of :last_name }
  it { is_expected.to validate_presence_of :first_name }
  it { is_expected.to validate_presence_of :display_name }
  it { is_expected.to allow_value('Student').for(:type) }
  it { is_expected.to allow_value('Admin').for(:type) }
  it { is_expected.to allow_value('Ta').for(:type) }
  it { is_expected.to allow_value('TestServer').for(:type) }
  it { is_expected.not_to allow_value('OtherTypeOfUser').for(:type) }
  it { is_expected.not_to allow_value('A!a.sa').for(:user_name) }
  it { is_expected.to allow_value('Ads_-hb').for(:user_name) }
  it { is_expected.to allow_value('-22125-k1lj42_').for(:user_name) }

  describe 'TestServer' do
    subject { create :test_server }
    it { is_expected.to allow_value('A!a.sa').for(:user_name) }
    it { is_expected.to allow_value('.autotest').for(:user_name) }
  end

  describe 'uniqueness validation' do
    subject { create :admin }
    it { is_expected.to validate_uniqueness_of :user_name }
  end

  context 'A good User model' do
    it 'should be able to create a student' do
      create(:student)
    end
    it 'should be able to create an admin' do
      create(:admin)
    end
    it 'should be able to create a grader' do
      create(:ta)
    end
  end

  context 'User creation validations' do
    before :each do
      new_user = { user_name: '   ausername   ',
                   first_name: '   afirstname ',
                   last_name: '   alastname  ' }
      @user = Student.new(new_user)
      @user.type = 'Student'
    end

    it 'should strip all strings with white space from user name' do
      expect(@user.save).to eq true
      expect(@user.user_name).to eq 'ausername'
      expect(@user.first_name).to eq 'afirstname'
      expect(@user.last_name).to eq 'alastname'
    end

    it 'should set default display name to be first + last name' do
      expect(@user.save).to eq true
      expect(@user.display_name).to eq "#{@user.first_name} #{@user.last_name}"
    end
  end

  context 'The repository permissions file' do
    context 'should be upated' do
      it 'when creating an admin' do
        expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
        create(:admin)
      end
      it 'when destroying an admin' do
        admin = create(:admin)
        expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
        admin.destroy
      end
    end
    context 'should not be updated' do
      it 'when creating a ta' do
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        create(:ta)
      end
      it 'when destroying a ta without memberships' do
        ta = create(:ta)
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        ta.destroy
      end
      it 'when creating a student' do
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        create(:student)
      end
      it 'when destroying a student without memberships' do
        student = create(:student)
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        student.destroy
      end
    end
  end
  describe '.authenticate' do
    context 'bad character' do
      it 'should not allow a null char in the username' do
        expect(User.authenticate("a\0b", '123')).to eq User::AUTHENTICATE_BAD_CHAR
      end
      it 'should not allow a null char in the password' do
        expect(User.authenticate('ab', "12\0a3")).to eq User::AUTHENTICATE_BAD_CHAR
      end
      it 'should not allow a newline in the username' do
        expect(User.authenticate("a\nb", '123')).to eq User::AUTHENTICATE_BAD_CHAR
      end
      it 'should not allow a newline in the username' do
        expect(User.authenticate('ab', "12\na3")).to eq User::AUTHENTICATE_BAD_CHAR
      end
    end
    context 'bad platform' do
      it 'should not allow validation if the server OS is windows' do
        stub_const('RUBY_PLATFORM', 'mswin')
        expect(User.authenticate('ab', '123')).to eq User::AUTHENTICATE_BAD_PLATFORM
      end
    end
    context 'without a custom exit status messages' do
      context 'a successful login' do
        it 'should return a success message' do
          allow_any_instance_of(Process::Status).to receive(:exitstatus).and_return(0)
          expect(User.authenticate('ab', '123')).to eq User::AUTHENTICATE_SUCCESS
        end
      end
      context 'an unsuccessful login' do
        it 'should return a failure message' do
          allow_any_instance_of(Process::Status).to receive(:exitstatus).and_return(1)
          expect(User.authenticate('ab', '123')).to eq User::AUTHENTICATE_ERROR
        end
      end
    end
    context 'with a custom exit status message' do
      before do
        allow(Settings).to receive(:validate_custom_status_message).and_return('2' => 'a two!', '3' => 'a three!')
      end
      context 'a successful login' do
        it 'should return a success message' do
          allow_any_instance_of(Process::Status).to receive(:exitstatus).and_return(0)
          expect(User.authenticate('ab', '123')).to eq User::AUTHENTICATE_SUCCESS
        end
      end
      context 'an unsuccessful login' do
        it 'should return a failure message with a 1' do
          allow_any_instance_of(Process::Status).to receive(:exitstatus).and_return(1)
          expect(User.authenticate('ab', '123')).to eq User::AUTHENTICATE_ERROR
        end
        it 'should return a failure message with a 4' do
          allow_any_instance_of(Process::Status).to receive(:exitstatus).and_return(4)
          expect(User.authenticate('ab', '123')).to eq User::AUTHENTICATE_ERROR
        end
        it 'should return a custom message with a 2' do
          allow_any_instance_of(Process::Status).to receive(:exitstatus).and_return(2)
          expect(User.authenticate('ab', '123')).to eq '2'
        end
        it 'should return a custom message with a 3' do
          allow_any_instance_of(Process::Status).to receive(:exitstatus).and_return(3)
          expect(User.authenticate('ab', '123')).to eq '3'
        end
      end
    end
  end

  describe '#visible_assessments' do
    let(:new_section) { create(:section) }
    let(:assignment_visible) do
      create(:assignment,
             due_date: 2.days.from_now,
             assignment_properties_attributes: { section_due_dates_type: true })
    end
    let(:section_due_date_visible) do
      create(:section_due_date, assessment: assignment_visible,
                                section: new_section,
                                due_date: 2.days.from_now,
                                is_hidden: false)
    end
    let(:assignment_hidden) do
      create(:assignment,
             due_date: 2.days.from_now,
             assignment_properties_attributes: { section_due_dates_type: true })
    end
    let(:section_due_date_hidden) do
      create(:section_due_date, assessment: assignment_hidden,
                                section: new_section,
                                due_date: 2.days.from_now,
                                is_hidden: true)
    end
    context 'when there are no assessments' do
      let(:new_user) { create :student }
      it 'should return an empty list' do
        expect(new_user.visible_assessments).to be_empty
      end
    end
    context 'when there are assessments' do
      before(:each) do
        section_due_date_hidden
        section_due_date_visible
      end
      context 'when section_due_dates disabled' do
        let(:new_user_2) { create :student }
        it 'does return all unhiddden assignments' do
          expect(new_user_2.visible_assessments).to contain_exactly(assignment_visible, assignment_hidden)
        end
      end
      context 'when user has one visible assignment' do
        let(:new_user) { create :student, section_id: new_section.id }

        it 'does return a list containing that assignment' do
          expect(new_user.visible_assessments).to contain_exactly(assignment_visible)
        end
      end
      context 'when user has no section' do
        let(:new_user_2) { create :student }
        it 'does return all section-hidden assignments' do
          expect(new_user_2.visible_assessments).to contain_exactly(assignment_visible, assignment_hidden)
        end
      end
      context 'when a user is from a different section' do
        let(:section2) { create :section }
        let(:new_user_2) { create :student, section_id: section2 }
        it 'does return all visible assignments' do
          expect(new_user_2.visible_assessments).to contain_exactly(assignment_visible, assignment_hidden)
        end
      end
      context 'when an assignment is hidden' do
        let(:hidden_assignment) do
          create :assignment,
                 due_date: 2.days.from_now,
                 is_hidden: true,
                 assignment_properties_attributes: { section_due_dates_type: true }
        end
        let(:new_user) { create :student }
        it 'does not return the hidden assignment' do
          expect(new_user.visible_assessments).to contain_exactly(assignment_visible, assignment_hidden)
        end
      end
      context 'when a visible assignment is given' do
        let(:new_user) { create :student, section_id: new_section.id }
        it 'does return an array with the assignment' do
          expect(new_user.visible_assessments(assessment_id: assignment_visible.id))
            .to contain_exactly(assignment_visible)
        end
      end
      context 'when a hidden assignment is given' do
        let(:new_user) { create :student, section_id: new_section.id }
        it 'does return an empty array' do
          expect(new_user.visible_assessments(assessment_id: assignment_hidden.id)).to be_empty
        end
      end
    end

    context 'when using grade entry forms' do
      let(:grade_entry_form_visible) { create :grade_entry_form }
      let(:grade_entry_section_visible) do
        create :section_due_date, assessment: grade_entry_form_visible,
                                  section: new_section, is_hidden: false
      end

      let(:grade_entry_form_hidden) { create :grade_entry_form }
      let(:grade_entry_section_hidden) do
        create :section_due_date, assessment: grade_entry_form_hidden,
                                  section: new_section, is_hidden: true
      end

      context 'when there are assessments' do
        before(:each) do
          grade_entry_section_visible
          grade_entry_section_hidden
        end
        context 'when section_due_dates disabled' do
          let(:new_user_2) { create :student }
          it 'does return all unhiddden assignments' do
            expect(new_user_2.visible_assessments).to contain_exactly(grade_entry_form_visible, grade_entry_form_hidden)
          end
        end
        context 'when user has one visible assignment' do
          let(:new_user) { create :student, section_id: new_section.id }

          it 'does return a list containing that assignment' do
            expect(new_user.visible_assessments).to contain_exactly(grade_entry_form_visible)
          end
        end
        context 'when user has no section' do
          let(:new_user_2) { create :student }
          it 'does return all section-hidden assignments' do
            expect(new_user_2.visible_assessments).to contain_exactly(grade_entry_form_visible, grade_entry_form_hidden)
          end
        end
        context 'when a user is from a different section' do
          let(:section2) { create :section }
          let(:new_user_2) { create :student, section_id: section2 }
          it 'does return all visible assignments' do
            expect(new_user_2.visible_assessments).to contain_exactly(grade_entry_form_visible, grade_entry_form_hidden)
          end
        end
        context 'when an assignment is hidden' do
          let(:hidden_grade_entry_form) do
            create :grade_entry_form,
                   due_date: 2.days.from_now,
                   is_hidden: true
          end
          let(:new_user) { create :student }
          it 'does not return the hidden assignment' do
            expect(new_user.visible_assessments).to contain_exactly(grade_entry_form_visible, grade_entry_form_hidden)
          end
        end
        context 'when a visible assignment is given' do
          let(:new_user) { create :student, section_id: new_section.id }
          it 'does return an array with the assignment' do
            expect(new_user.visible_assessments(assessment_id: grade_entry_form_visible.id))
              .to contain_exactly(grade_entry_form_visible)
          end
        end
        context 'when a hidden assignment is given' do
          let(:new_user) { create :student, section_id: new_section.id }
          it 'does return an empty array' do
            expect(new_user.visible_assessments(assessment_id: grade_entry_form_hidden.id)).to be_empty
          end
        end
      end
    end
  end
end
