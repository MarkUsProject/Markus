require 'spec_helper'

describe TestScriptResult do
  it { is_expected.to belong_to(:submission) }
  it { is_expected.to belong_to(:test_script) }

  it { is_expected.to validate_presence_of(:test_script) }
  it { is_expected.to validate_presence_of(:marks_earned) }
  it { is_expected.to validate_presence_of(:repo_revision) }

  it { is_expected.to validate_numericality_of(:marks_earned) }

  context 'test script result' do
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
                                                  repo_revision: 0)
    end

    # create
    context 'A valid test script result' do
      it 'return true when a valid test script result is created' do
        expect(@test_script_result).to be_valid
        expect(@test_script_result.save).to be true
      end

      it 'return true when a valid test script result is created even if the marks_earned is zero' do
        @test_script_result.marks_earned = 0
        expect(@test_script_result).to be_valid
        expect(@test_script_result.save).to be true
      end
    end

    # update
    context 'An invalid test script result' do
      context 'test script result expected to be invalid when test script is nil' do
        it 'return false when test script is nil' do
          @test_script_result.test_script = nil
          expect(@test_script_result).not_to be_valid
        end
      end

      context 'test script result expected to be invalid when the marks_earned is negative' do
        it 'return false when the marks_earned is negative' do
          @test_script_result.marks_earned = -1
          expect(@test_script_result).not_to be_valid
        end
      end

      context 'test script result expected to be invalid when the marks_earned is not an integer' do
        it 'return false when the marks_earned is not an integer' do
          @test_script_result.marks_earned = 0.5
          expect(@test_script_result).not_to be_valid
        end
      end
    end

    #delete
    context 'MarkUs' do
      it 'be able to delete a test script result' do
        expect(@test_script_result).to be_valid
        expect{@test_script_result.destroy}.to change {TestScriptResult.count}.by(-1)
      end
    end
  end
end
