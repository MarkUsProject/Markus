require 'spec_helper'

describe TestScript do
  it { is_expected.to belong_to(:assignment) }
  it { is_expected.to have_many(:test_script_results) }
  it { is_expected.to validate_presence_of :assignment }
  it { is_expected.to validate_presence_of :seq_num }
  it { is_expected.to validate_presence_of :script_name }
  it { is_expected.to validate_presence_of :max_marks }

  # For booleans, should validate_presence_of does
  # not work: see the Rails API documentation for should validate_presence_of
  # (Model validations)
  # should validate_presence_of does not work for boolean value false.
  # Using should allow_value instead

  it { is_expected.to allow_value(true).for(:run_by_instructors) }
  it { is_expected.to allow_value(false).for(:run_by_instructors) }
  it { is_expected.to allow_value(true).for(:run_by_students) }
  it { is_expected.to allow_value(false).for(:run_by_students) }
  it { is_expected.to allow_value(true).for(:halts_testing) }
  it { is_expected.to allow_value(false).for(:halts_testing) }


  it { is_expected.to validate_presence_of :display_description }
  it { is_expected.to validate_presence_of :display_run_status }
  it { is_expected.to validate_presence_of :display_marks_earned }
  it { is_expected.to validate_presence_of :display_input }
  it { is_expected.to validate_presence_of :display_expected_output }
  it { is_expected.to validate_presence_of :display_actual_output }

  it { is_expected.to validate_numericality_of :seq_num }
  it { is_expected.to validate_numericality_of :max_marks }
  
  context 'A good User model' do
    it 'should be able to create a student' do
      student = create(:student)
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
  end
end
