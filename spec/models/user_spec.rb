require 'rails_helper'

describe User do
  it { is_expected.to have_many(:key_pairs).dependent(:destroy) }
  it { is_expected.to validate_presence_of :user_name }
  it { is_expected.to validate_presence_of :last_name }
  it { is_expected.to validate_presence_of :first_name }
  it { is_expected.to validate_presence_of :display_name }
  it { is_expected.to allow_value('AutotestUser').for(:type) }
  it { is_expected.to allow_value('EndUser').for(:type) }
  it { is_expected.not_to allow_value('OtherTypeOfUser').for(:type) }
  it { is_expected.not_to allow_value('A!a.sa').for(:user_name) }
  it { is_expected.to allow_value('Ads_-hb').for(:user_name) }
  it { is_expected.to allow_value('-22125-k1lj42_').for(:user_name) }
  it { is_expected.to validate_inclusion_of(:locale).in_array(I18n.available_locales.map(&:to_s)) }
  it { is_expected.to have_many(:roles) }
  it { is_expected.to have_many(:lti_users) }

  it 'fails with error message when invalid name format' do
    user = create(:end_user)
    user.user_name = 'Invalid!@'
    error_key = 'activerecord.errors.models.user.attributes.user_name.invalid'
    expected_error = I18n.t(error_key, attribute: 'User Name')
    expect(user).not_to be_valid
    expect(user.errors[:user_name]).to include(expected_error)
  end

  describe 'AutotestUser' do
    subject { create(:autotest_user) }

    it { is_expected.to allow_value('A!a.sa').for(:user_name) }
    it { is_expected.to allow_value('.autotest').for(:user_name) }
  end

  describe 'uniqueness validation' do
    subject { create(:end_user) }

    it { is_expected.to validate_uniqueness_of :user_name }
  end

  context 'A good User model' do
    it 'should be able to create an end_user user' do
      user = create(:end_user)
      expect(user.persisted?).to be true
    end
  end

  context 'User creation validations' do
    before do
      new_user = { user_name: '   ausername   ',
                   first_name: '   afirstname ',
                   last_name: '   alastname  ' }
      @user = EndUser.new(new_user)
    end

    it 'should strip all strings with white space from user name' do
      expect(@user.save).to be true
      expect(@user.user_name).to eq 'ausername'
      expect(@user.first_name).to eq 'afirstname'
      expect(@user.last_name).to eq 'alastname'
    end

    it 'should set default display name to be first + last name' do
      expect(@user.save).to be true
      expect(@user.display_name).to eq "#{@user.first_name} #{@user.last_name}"
    end
  end

  describe '.authenticate' do
    context 'bad character' do
      it 'should not allow a null char in the username' do
        expect(User.authenticate("a\0b", password: '123')).to eq User::AUTHENTICATE_BAD_CHAR
      end

      it 'should not allow a null char in the password' do
        expect(User.authenticate('ab', password: "12\0a3")).to eq User::AUTHENTICATE_BAD_CHAR
      end

      it 'should not allow a newline in the username' do
        expect(User.authenticate("a\nb", password: '123')).to eq User::AUTHENTICATE_BAD_CHAR
      end

      it 'should not allow a newline in the password' do
        expect(User.authenticate('ab', password: "12\na3")).to eq User::AUTHENTICATE_BAD_CHAR
      end
    end

    context 'bad platform' do
      it 'should not allow validation if the server OS is windows' do
        stub_const('RUBY_PLATFORM', 'mswin')
        expect(User.authenticate('ab', password: '123')).to eq User::AUTHENTICATE_BAD_PLATFORM
      end
    end

    context 'without a custom exit status messages' do
      before do
        allow(Settings).to receive(:validate_file).and_return(Rails.root
                                                                   .join('spec/fixtures/files/dummy_invalidate.sh'))
      end

      context 'a successful login' do
        it 'should return a success message' do
          expect(User.authenticate('ab', password: '123')).to eq User::AUTHENTICATE_SUCCESS
        end
      end

      context 'an unsuccessful login' do
        it 'should return a failure message' do
          expect(User.authenticate('exit3', password: '123')).to eq User::AUTHENTICATE_ERROR
        end
      end

      context 'with a remote validation file' do
        before do
          allow(Settings).to receive_messages(remote_validate_file: Rails.root
                                                     .join('spec/fixtures/files/dummy_remote_validate.sh'),
                                              validate_ip: true)
        end

        it 'should return a failure with no ip' do
          expect(User.authenticate('exit3', password: '123',
                                            auth_type: User::AUTHENTICATE_REMOTE)).to eq User::AUTHENTICATE_ERROR
        end

        it 'should return a failure with a disallowed ip' do
          expect(User.authenticate('exit3', password: '123', ip: '192.168.0.1',
                                            auth_type: User::AUTHENTICATE_REMOTE)).to eq User::AUTHENTICATE_ERROR
        end

        it 'should return a success with an allowed ip' do
          expect(User.authenticate('exit3', password: '123', ip: '0.0.0.0',
                                            auth_type: User::AUTHENTICATE_REMOTE)).to eq User::AUTHENTICATE_SUCCESS
        end
      end
    end

    context 'with a custom exit status message' do
      before do
        allow(Settings).to receive_messages(
          validate_custom_status_message: { '2' => 'a two!', '3' => 'a three!' },
          validate_file: Rails.root.join('spec/fixtures/files/dummy_invalidate.sh')
        )
      end

      context 'a successful login' do
        it 'should return a success message' do
          expect(User.authenticate('ab', password: '123')).to eq User::AUTHENTICATE_SUCCESS
        end
      end

      context 'an unsuccessful login' do
        it 'should return a failure message with a 1' do
          expect(User.authenticate('exit1', password: '123')).to eq User::AUTHENTICATE_ERROR
        end

        it 'should return a failure message with a 4' do
          expect(User.authenticate('exit4', password: '123')).to eq User::AUTHENTICATE_ERROR
        end

        it 'should return a custom message with a 2' do
          expect(User.authenticate('exit2', password: '123')).to eq '2'
        end

        it 'should return a custom message with a 3' do
          expect(User.authenticate('exit3nomsg', password: '123')).to eq '3'
        end
      end
    end
  end

  describe '#admin_courses' do
    let(:course1) { create(:course) }
    let(:course2) { create(:course) }
    let(:admin) { create(:admin_user) }
    let(:instructor1) { create(:instructor, course: course1) }
    let(:student) { create(:student, course: course2) }

    it 'returns only courses where an instructor is an admin' do
      expect(instructor1.user.admin_courses).to contain_exactly(course1)
    end

    it 'returns no courses for a student' do
      expect(student.user.admin_courses).to be_empty
    end

    it 'returns all courses for an admin user' do
      expect(admin.admin_courses).to contain_exactly(course1, course2)
    end
  end

  context 'get orphaned users' do
    let!(:course) { create(:course) }
    let!(:admin) { create(:admin_user) }
    let!(:end_user) { create(:end_user) }
    let!(:autotest_user) { create(:autotest_user) }
    let!(:student) { create(:student, course: course) }

    it 'should return orphaned user of type AdminUser' do
      expect(AdminUser.get_orphaned_users).to contain_exactly(admin)
    end

    it 'should return orphaned user of type AutotestUser' do
      expect(AutotestUser.get_orphaned_users).to contain_exactly(autotest_user)
    end

    it 'should return orphaned user of type EndUser' do
      expect(EndUser.get_orphaned_users).to contain_exactly(end_user)
    end

    it 'should not include student who is in a course as an orphaned user' do
      expect(User.get_orphaned_users).not_to include(student)
    end
  end
end
