describe TestScript do
  it { is_expected.to belong_to(:assignment) }
  it { is_expected.to have_many(:test_script_results) }
  it { is_expected.to validate_presence_of :seq_num }
  it { is_expected.to validate_presence_of :file_name }

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

  # create
  context 'A valid script file' do
    before(:each)  do
      @asst = create(:assignment,
                     section_due_dates_type: false,
                     due_date: 2.days.from_now)

      @script_file = TestScript.create(assignment_id:             @asst.id,
                                      seq_num:                    1,
                                      file_name:                  'script.sh',
                                      description:                'This is a bash script file',
                                      timeout:                    30,
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
      expect(@script_file).to be_valid
    end

    it 'return true when a valid file is created even if the description is empty' do
      @script_file.description = ''
      expect(@script_file).to be_valid
    end
  end

  # update
  context 'An invalid script file' do
    before(:each)  do
      @asst = create(:assignment,
                     section_due_dates_type: false,
                     due_date: 2.days.from_now)
      display_option = %w(do_not_display display_after_submission display_after_collection)

      @valid_script_file = TestScript.create(assignment_id:               @asst.id,
                                           seq_num:                     1,
                                           file_name:                   'validscript.sh',
                                           description:                 'This is a bash script file',
                                           timeout:                     30,
                                           run_by_instructors:          true,
                                           run_by_students:             true,
                                           halts_testing:               false,
                                           display_description:         display_option[0],
                                           display_run_status:          display_option[1],
                                           display_marks_earned:        display_option[2],
                                           display_input:               display_option[0],
                                           display_expected_output:     display_option[1],
                                           display_actual_output:       display_option[2])

      @invalid_script_file = TestScript.create(assignment_id:             @asst.id,
                                             seq_num:                   2,
                                             file_name:                 'invalidscript.sh',
                                             description:               'This is a bash script file',
                                             timeout:                   30,
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
      it 'return false when assignment is nil' do
        @invalid_script_file.assignment_id = nil
        expect(@invalid_script_file).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the description is nil' do
      it 'return false when the description is nil' do
        @invalid_script_file.description = nil
        expect(@invalid_script_file).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the timeout is negative' do
      it 'return false when the timeout is negative' do
        @invalid_script_file.timeout = -1
        expect(@invalid_script_file).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the timeout is zero' do
      it 'return false when the timeout is zero' do
        @invalid_script_file.timeout = 0
        expect(@invalid_script_file).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the timeout is too big' do
      it 'return false when the timeout is too big' do
        @invalid_script_file.timeout = 3601
        expect(@invalid_script_file).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the timeout is not integer' do
      it 'return false when the timeout is not integer' do
        @invalid_script_file.timeout = 0.5
        expect(@invalid_script_file).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the file_name already exists in the same assignment' do
      it 'return false when the file_name already exists' do
        @invalid_script_file.file_name = 'validscript.sh'
        expect(@invalid_script_file).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the seq_num already exists in the same assignment' do
      it 'return true when the seq_num already exists' do
        @invalid_script_file.seq_num = 2
        expect(@invalid_script_file).to be_valid
      end
    end

    context 'script file expected to be invalid when the display_description option has an invalid option' do
      it 'return false when the display_description option has an invalid option' do
        @invalid_script_file.display_description = 'display_after_due_date'
        expect(@invalid_script_file).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the display_run_status option has an invalid option' do
      it 'return false when the display_run_status option has an invalid option' do
        @invalid_script_file.display_run_status = 'display_after_submit'
        expect(@invalid_script_file).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the display_marks_earned option has an invalid option' do
      it 'return false when the display_marks_earned option has an invalid option' do
        @invalid_script_file.display_marks_earned = 'display_before_due_date'
        expect(@invalid_script_file).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the display_input option has an invalid option' do
      it 'return false when the display_input option has an invalid option' do
        @invalid_script_file.display_input = 'display_before_collection'
        expect(@invalid_script_file).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the display_expected_output option has an invalid option' do
      it 'return false when the display_expected_output option has an invalid option' do
        @invalid_script_file.display_expected_output = 'display_at_submission'
        expect(@invalid_script_file).not_to be_valid
      end
    end

    context 'script file expected to be invalid when the display_actual_output option has an invalid option' do
      it 'return false when the display_actual_output option has an invalid option' do
        @invalid_script_file.display_actual_output = 'display_at_collection'
        expect(@invalid_script_file).not_to be_valid
      end
    end
  end
end
