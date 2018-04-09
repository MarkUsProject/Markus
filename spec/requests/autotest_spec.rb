require 'spec_helper'

##
# These tests are to test the interaction with the markus-autotester.
# Specifically, it sends mock student submission files to the autotester,
# waits for it to return a test result and then tests that Markus either
# populates the relevant tables properly or raises an appropriate error.
#
# The student submission files can be found in:
#   spec/fixtures/files/submission_files/autotest
#
# For a full explanation of what each file is designed to test, see the
# docstring at the top of each file directly below the import statements.
#
# These tests are divided into several categories, which can be determined
# by inspecting the basename of each submission file:
#
#   - *_2s_1.py : these tests have two test cases evaluated by different
#                 test scripts and the first test case contains some error
#   - *_2s_2.py : these tests have two test cases evaluated by different
#                 test scripts and the second test case contains some error
#   - *_2t_1.py : these tests have two test cases evaluated by the same
#                 test script and the first test case contains some error
#   - *_2s_2.py : these tests have two test cases evaluated by the same
#                 test scripts and the second test case contains some error
#   - *_A.py    : this submission file sets up some condition that is evaluated
#                 by the corresponding *_B.py file. This one must be run first
#   - *_B.py    : this submission file tests some condition that is set up by
#                 the corresponding *_A.py file. This one must be run second
#   - all others: tests where the order doesn't matter, see docstring for details
#

RSpec.configure do |config|
  # NOTE: transactions will interfere with receiving
  # an API call from the markus-autotester and so should
  # not be used
  config.use_transactional_fixtures = false
  config.include AutotestHelper
end

describe 'Autotester', skip_db_clean: true do

  before(:all) do
    @test_server_user = create_with_api_key(:test_server)
    @test_names = get_test_names
  end

  after(:all) do
    # DatabaseCleaner.clean_with :truncation
    FileUtils.rm_rf Dir.glob File.join(MarkusConfigurator.autotest_client_dir, '*')
  end

  def test_result(test_name)
    TestResult.joins(:test_script_result)
              .where(test_script_results: { grouping_id: @grouping_ids[test_name] })
  end

  def test_script_result(test_name)
    TestScriptResult.joins(:test_results)
                    .where(test_script_results: { grouping_id: @grouping_ids[test_name] })
  end

  context 'when current user is admin' do
    before(:all) { @user = create_with_api_key(:admin) }

    context 'run one step tests' do
      context 'expect no timeouts' do
        before :all do
          test_list = @test_names.select { |tn| !'AB'.include?(tn[-1]) && !tn.include?('timeout') }
          @grouping_ids = run_autotests test_list, @user, @test_server_user, global_timeout=60
        end
        context 'test possible statuses' do
          it 'should accept pass status' do
            expect(test_result('pass').first).to have_attributes(completion_status: 'pass')
          end
          it 'should accept fail status' do
            expect(test_result('failure').first).to have_attributes(completion_status: 'fail')
          end
          it 'should accept partial pass status' do
            expect(test_result('partial_pass').first).to have_attributes(completion_status: 'partial')
          end
          it 'should accept error status' do
            expect(test_result('error').first).to have_attributes(completion_status: 'error')
          end
          it 'should set invalid status to error' do
            expect(test_result('invalid_status').first).to have_attributes(completion_status: 'error')
          end
          it 'should give no marks for invalid status' do
            expect(test_result('invalid_status').first).to have_attributes(marks_earned: 0)
          end
          it 'should stop processing tests after an error all status' do
            expect(test_result('error_all').size).to eq(2)
          end
          it 'should set error all status to error' do
            expect(test_result('error_all').last).to have_attributes(completion_status: 'error')
          end
          it 'should give zero marks if error all status is present' do
            expect(test_script_result('error_all').first).to have_attributes(marks_earned: 0)
          end
        end
        context 'test malformed xml' do
          it 'should set status to error' do
            expect(test_result('bad_xml_simple').first).to have_attributes(completion_status: 'error')
          end
          it 'should give zero marks' do
            expect(test_result('bad_xml_simple').first).to have_attributes(marks_earned: 0)
          end
          it 'should still display stderr if xml is malformed' do
            r = test_result('bad_xml_with_error').where('name LIKE ?', '%stderr%').pluck(:actual_output)
            expect(r[0]).to include('some error')
          end
          it 'should interfere with later tests in other scripts' do
            expect(test_result('bad_xml_2s_1')).to all have_attributes(completion_status: 'error')
          end
          xit 'should not interfere with previous tests in other scripts' do
            r = test_result('bad_xml_2s_2').pluck(:completion_status)
            expect(r).to include('pass', 'error')
          end
          it 'should interfere with later tests in the same script' do
            expect(test_result('bad_xml_2t_1')).to all have_attributes(completion_status: 'error')
          end
          xit 'should not interfere with previous tests in the same script' do
            r = test_result('bad_xml_2t_2').pluck(:completion_status)
            expect(r).to include('pass', 'error')
          end
        end
        context 'test xml with non-standard structure' do
          it 'should skip tests not wrapped in <test> tags' do
            expect(test_result('test_tag_missing').first.actual_output).to include('Test results are empty')
          end
          it 'should permit tests to be missing <input> tags' do
            expect(test_result('input_tag_missing').first).to have_attributes(completion_status: 'pass')
          end
          it 'should permit tests to be missing <expected> tags' do
            expect(test_result('expected_tag_missing').first).to have_attributes(completion_status: 'pass')
          end
          it 'should permit tests to be missing <actual> tags' do
            expect(test_result('actual_tag_missing').first).to have_attributes(completion_status: 'pass')
          end
          it 'should set status to error if missing <marks_earned> tag' do
            expect(test_result('marks_earned_missing').first).to have_attributes(completion_status: 'error')
          end
          it 'should report tag is missing if missing <marks_earned> tag' do
            expect(test_result('marks_earned_missing').first.actual_output).to include('Earned marks are missing')
          end
          it 'should set status to error if missing <marks_total> tag' do
            expect(test_result('marks_total_missing').first).to have_attributes(completion_status: 'error')
          end
          it 'should report tag is missing if missing <marks_total> tag' do
            expect(test_result('marks_total_missing').first.actual_output).to include('Total marks are missing')
          end
          context 'missing <name> tag' do
            it 'should set status to error' do
              expect(test_result('name_tag_missing_simple').first).to have_attributes(completion_status: 'error')
            end
            xit 'should not interfere with a later test in the same script' do
              r = test_result('name_tag_missing_2t_1').pluck(:completion_status)
              expect(r).to include('pass', 'error')
            end
            it 'should not interfere with a previous test in the same script' do
              r = test_result('name_tag_missing_2t_2').pluck(:completion_status)
              expect(r).to include('pass', 'error')
            end
            it 'should not interfere with a later test in a different script' do
              r = test_result('name_tag_missing_2s_1').pluck(:completion_status)
              expect(r).to include('pass', 'error')
            end
            it 'should not interfere with a previous test in a different script' do
              r = test_result('name_tag_missing_2s_2').pluck(:completion_status)
              expect(r).to include('pass', 'error')
            end
          end
          context 'missing <status> tag' do
            it 'should set status to error' do
              expect(test_result('status_tag_missing_simple').first).to have_attributes(completion_status: 'error')
            end
            it 'should not interfere with a later test in the same script' do
              r = test_result('status_tag_missing_2t_1').pluck(:completion_status)
              expect(r).to include('pass', 'error')
            end
            it 'should not interfere with a previous test in the same script' do
              r = test_result('status_tag_missing_2t_2').pluck(:completion_status)
              expect(r).to include('pass', 'error')
            end
            it 'should not interfere with a later test in a different script' do
              r = test_result('status_tag_missing_2s_1').pluck(:completion_status)
              expect(r).to include('pass', 'error')
            end
            it 'should not interfere with a previous test in a different script' do
              r = test_result('status_tag_missing_2s_2').pluck(:completion_status)
              expect(r).to include('pass', 'error')
            end
          end
        end
        context 'test data type of tag contents' do
          it 'should permit marks earned to contain a decimal value' do
            expect(test_result('partial_pass_with_float').first.marks_earned).to be_within(0.0001).of(0.5)
          end
        end
        context 'test error messages' do
          it 'should report an error when an exception is raised' do
            expect(test_result('raise_error').where('name LIKE ?', '%stderr%')).to be_present
          end
          it 'should report an error when something is written to stderr' do
            expect(test_result('write_to_stderr').where('name LIKE ?', '%stderr%')).to be_present
          end
        end
        xcontext 'test behaviours that should be prevented/allowed by permission settings' do
          it 'should not be able to delete test files' do
            expect(test_result('delete_file').first).to have_attributes(completion_status: 'pass')
          end
          it 'should not be able to modify test files' do
            expect(test_result('modify_file').first).to have_attributes(completion_status: 'pass')
          end
          it 'should be able to write a file to the current directory' do
            expect(test_result('write_file').first).to have_attributes(completion_status: 'pass')
          end
          it 'should not be able to write a file outside the current directory' do
            expect(test_result('write_to_parent').first).to have_attributes(completion_status: 'pass')
          end
          xit 'should not be able to allocate 10GB of memory' do
            expect(test_result('memory_allocate').where('name LIKE ?', '%stderr%').first.actual_output).to include('OSError', 'memory')
          end
        end
      end
      context 'expect timeouts' do
        before :all do
          test_list = @test_names.select { |tn| !'AB'.include?(tn[-1]) && tn.include?('timeout') }
          @grouping_ids = run_autotests test_list, @user, @test_server_user, global_timeout=60
        end
        it 'should timeout' do
          expect(test_result('timeout')).to all have_attributes(completion_status: 'error')
        end
        it 'should still report errors raised before the timeout' do
          expect(test_result('timeout_with_uncaught_errors').where('name LIKE ?', '%stderr%').first.actual_output).to include('uncaught_error_test')
        end
      end
    end
    context 'run two step tests' do
      context 'expect no timeouts' do
        before :all do
          test_list = @test_names.select { |tn| 'AB'.include?(tn[-1]) && !tn.include?('timeout') }
          a_list = test_list.select { |tn| 'A' == tn[-1] }
          b_list = test_list.select { |tn| 'B' == tn[-1] }
          @grouping_ids = run_autotests a_list, @user, @test_server_user, global_timeout=60
          @grouping_ids.merge!(run_autotests b_list, @user, @test_server_user, global_timeout=60)
        end
        it 'should clean up all files' do
          expect(test_result('leave_file_behind_A').first).to have_attributes(completion_status: 'pass')
          expect(test_result('leave_file_behind_B').first).to have_attributes(completion_status: 'pass')
        end
        it 'should clean up all processes created during the test' do
          expect(test_result('spawn_proc_A').first).to have_attributes(completion_status: 'pass')
          expect(test_result('spawn_proc_B').first).to have_attributes(completion_status: 'pass')
        end
      end
      context 'expect timeouts' do
        before :all do
          test_list = @test_names.select { |tn| 'AB'.include?(tn[-1]) && tn.include?('timeout') }
          a_list = test_list.select { |tn| 'A' == tn[-1] }
          b_list = test_list.select { |tn| 'B' == tn[-1] }
          @grouping_ids = run_autotests a_list, @user, @test_server_user, global_timeout=60
          @grouping_ids.merge!(run_autotests b_list, @user, @test_server_user, global_timeout=60)
        end
        it 'should clean up all processes created during the test' do
          expect(test_result('spawn_proc_with_timeout_A').first.actual_output).to include('timeout')
          expect(test_result('spawn_proc_with_timeout_B').first).to have_attributes(completion_status: 'pass')
        end
      end
    end
  end
end


