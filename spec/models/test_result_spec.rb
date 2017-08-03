require 'spec_helper'

describe TestResult do
  it { is_expected.to belong_to(:test_script_result) }

  it { is_expected.to validate_presence_of(:test_script_result) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:completion_status) }
  it { is_expected.to validate_presence_of(:marks_earned) }

  it { is_expected.to validate_numericality_of(:marks_earned) }

  context 'test result' do
    before(:each) do
      @asst = create(:assignment)
      @grouping = create(:grouping, assignment: @asst)
      @sub = create(:submission, grouping: @grouping)
      @test_script = TestScript.create(
        assignment_id:             @asst.id,
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
      @test_script_result = TestScriptResult.create(submission: @sub,
                                                    grouping: @sub.grouping,
                                                    test_script: @test_script,
                                                    marks_earned: 5,
                                                    repo_revision: 0,
                                                    time: 0)
      @test_result = TestResult.create(
        test_script_result: @test_script_result,
        name:               'unit test 1',
        completion_status:  'pass',
        input:              '',
        actual_output:      '   ',
        expected_output:    'This is the expected output',
        marks_earned: 5
      )
    end

    # create
    context 'A valid test result' do
      it 'return true when a valid test result is created' do
        expect(@test_result).to be_valid
        expect(@test_result.save).to be true
      end

      it 'return true when a valid test result is created even if the input is empty' do
        @test_result.input = ''
        expect(@test_result).to be_valid
        expect(@test_result.save).to be true
      end

      it 'return true when a valid test result is created even if the actual_output is empty' do
        @test_result.actual_output = ''
        expect(@test_result).to be_valid
        expect(@test_result.save).to be true
      end

      it 'return true when a valid test result is created even if the expected_output is empty' do
        @test_result.expected_output = ''
        expect(@test_result).to be_valid
        expect(@test_result.save).to be true
      end
    end

    # update
    context 'An invalid test result' do
      context 'test result expected to be invalid when test script is nil' do
        it 'return false when test script result is nil' do
          @test_result.test_script_result = nil
          @test_result.save
          expect(@test_result).not_to be_valid
        end
      end

      context 'test result expected to be invalid when the input is nil' do
        it 'return false when the input is nil' do
          @test_result.input = nil
          expect(@test_result).not_to be_valid
        end
      end

      context 'test result expected to be invalid when the actual_output is nil' do
        it 'return false when the actual_output is nil' do
          @test_result.actual_output = nil
          expect(@test_result).not_to be_valid
        end
      end

      context 'test result expected to be invalid when the expected_output is nil' do
        it 'return false when the expected_output is nil' do
          @test_result.expected_output = nil
          expect(@test_result).not_to be_valid
        end
      end
    end

    #delete
    context 'MarkUs' do
      it 'be able to delete a test result' do
        expect(@test_result).to be_valid
        expect{@test_result.destroy}.to change {TestResult.count}.by(-1)
      end
    end
  end
end
