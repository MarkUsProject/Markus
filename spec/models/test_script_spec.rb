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

  # create
  context 'A valid script file' do
    before(:each)  do
      @asst = create(:assignment,
                     section_due_dates_type: false,
                     due_date: 2.days.from_now)

      @scriptfile = TestScript.create(assignment_id:             @asst.id,
                                      seq_num:                    1,
                                      script_name:                'script.sh',
                                      description:                'This is a bash script file',
                                      max_marks:                  5,
                                      run_by_instructors:         true,
                                      run_by_students:            true,
                                      halts_testing:              false,
                                      display_description:        'do_not_display',
                                      display_run_status:         'do_not_display',
                                      display_marks_earned:       'do_not_display',
                                      display_input:              'do_not_display',
                                      display_expected_output:    'do_not_display',
                                      display_actual_output:      'do_not_display')
    end

    it 'return true when a valid file is created' do
      expect(@scriptfile).to be_valid
    end

    it 'return true when a valid file is created even if the description is empty' do
      @scriptfile.description = ''
      expect(@scriptfile).to be_valid
    end

    it 'return true when a valid file is created even if the max_marks is zero' do
      @scriptfile.max_marks = 0
      expect(@scriptfile).to be_valid
    end
  end


  # update
  context 'An invalid script file' do
    before(:each)  do
      @asst = create(:assignment,
                     section_due_dates_type: false,
                     due_date: 2.days.from_now)
      display_option = %w(do_not_display display_after_submission display_after_collection)

      @validscriptfile = TestScript.create(assignment_id:               @asst.id,
                                         seq_num:                     1,
                                         script_name:                 'validscript.sh',
                                         description:                 'This is a bash script file',
                                         max_marks:                   5,
                                         run_by_instructors:          true,
                                         run_by_students:             true,
                                         halts_testing:               false,
                                         display_description:         display_option[0],
                                         display_run_status:          display_option[1],
                                         display_marks_earned:        display_option[2],
                                         display_input:               display_option[0],
                                         display_expected_output:     display_option[1],
                                         display_actual_output:       display_option[2])

      @invalidscriptfile = TestScript.create(assignment_id:             @asst.id,
                                           seq_num:                   2,
                                           script_name:               'invalidscript.sh',
                                           description:               'This is a bash script file',
                                           max_marks:                 5,
                                           run_by_instructors:        true,
                                           run_by_students:           true,
                                           halts_testing:             false,
                                           display_description:       display_option[2],
                                           display_run_status:        display_option[1],
                                           display_marks_earned:      display_option[0],
                                           display_input:             display_option[2],
                                           display_expected_output:   display_option[1],
                                           display_actual_output:     display_option[0])
    end

    context 'script file expected to be invalid when assignment is nil' do
      it 'return false when assignment is nii' do
        @invalidscriptfile.assignment_id = nil
        expect(@invalidscriptfile).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the description is nil' do
      it 'return false when the description is nil' do
        @invalidscriptfile.description = nil
        expect(@invalidscriptfile).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the max_marks is negative' do
      it 'return false when the max_marks is negative' do
        @invalidscriptfile.max_marks = -1
        expect(@invalidscriptfile).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the max_marks is not integer' do
      it 'return false when the max_marks is not integer' do
        @invalidscriptfile.max_marks = 0.5
        expect(@invalidscriptfile).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the script_name already exists in the same assignment' do
      it 'return false when the script_name already exists' do
        @invalidscriptfile.script_name = 'validscript.sh'
        expect(@invalidscriptfile).not_to be_valid
      end
    end

    context 'script file expected to be valid when the seq_num already exists in the same assignment' do
      it 'return true when the seq_num already exists' do
        @invalidscriptfile.seq_num = 2
        expect(@invalidscriptfile).to be_valid
      end
    end

    context 'script file expected to be invalid when the display_description option has an invalid option' do
      it 'return false when the display_description option has an invalid option' do
        @invalidscriptfile.display_description = 'display_after_due_date'
        expect(@invalidscriptfile).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the display_run_status option has an invalid option' do
      it 'return false when the display_run_status option has an invalid option' do
        @invalidscriptfile.display_run_status = 'display_after_submit'
        expect(@invalidscriptfile).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the display_marks_earned option has an invalid option' do
      it 'return false when the display_marks_earned option has an invalid option' do
        @invalidscriptfile.display_marks_earned = 'display_before_due_date'
        expect(@invalidscriptfile).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the display_input option has an invalid option' do
      it 'return false when the display_input option has an invalid option' do
        @invalidscriptfile.display_input = 'display_before_collection'
        expect(@invalidscriptfile).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the display_expected_output option has an invalid option' do
      it 'return false when the display_expected_output option has an invalid option' do
        @invalidscriptfile.display_expected_output = 'display_at_submission'
        expect(@invalidscriptfile).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the display_actual_output option has an invalid option' do
      it 'return false when the display_actual_output option has an invalid option' do
        @invalidscriptfile.display_actual_output = 'display_at_collection'
        expect(@invalidscriptfile).not_to be_valid
      end
    end
  end
end
