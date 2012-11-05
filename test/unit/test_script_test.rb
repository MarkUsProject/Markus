require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class TestScriptTest < ActiveSupport::TestCase
  should belong_to :assignment
  
  context "A valid script file" do
    
    setup do
      @scriptfile = TestScript.make(:seq_num                 => 1,
                                    :script_name             => 'script.sh',
                                    :description             => 'This is a bash script file',
                                    :max_marks               => 5,
                                    :run_on_submission       => true,
                                    :run_on_request          => true,
                                    :uses_token              => true,
                                    :halts_testing           => false,
                                    :display_description     => 'do_not_display',
                                    :display_run_status      => 'do_not_display',
                                    :display_marks_earned    => 'do_not_display',
                                    :display_input           => 'do_not_display',
                                    :display_expected_output => 'do_not_display',
                                    :display_actual_output   => 'do_not_display')
    end
    
    should "return true when a valid file is created" do
      assert @scriptfile.valid?
    end
    
    should "return true when the description is empty" do
      @scriptfile.description = ''
      assert @scriptfile.valid?
    end
    
    should "return true when the max_marks is zero" do
      @scriptfile.max_marks = 0
      assert @scriptfile.valid?
    end

  end
  
  context "An invalid script file" do
    
    setup do
      @validscriptfile = TestScript.make(:seq_num                 => 1,
                                         :script_name             => 'validscript.sh',
                                         :description             => 'This is a bash script file',
                                         :max_marks               => 5,
                                         :run_on_submission       => true,
                                         :run_on_request          => true,
                                         :uses_token              => true,
                                         :halts_testing           => false,
                                         :display_description     => 'do_not_display',
                                         :display_run_status      => 'do_not_display',
                                         :display_marks_earned    => 'do_not_display',
                                         :display_input           => 'do_not_display',
                                         :display_expected_output => 'do_not_display',
                                         :display_actual_output   => 'do_not_display')
                                         
      @invalidscriptfile = TestScript.make(:seq_num                 => 2,
                                           :script_name             => 'invalidscript.sh',
                                           :description             => 'This is a bash script file',
                                           :max_marks               => 5,
                                           :run_on_submission       => true,
                                           :run_on_request          => true,
                                           :uses_token              => true,
                                           :halts_testing           => false,
                                           :display_description     => 'do_not_display',
                                           :display_run_status      => 'do_not_display',
                                           :display_marks_earned    => 'do_not_display',
                                           :display_input           => 'do_not_display',
                                           :display_expected_output => 'do_not_display',
                                           :display_actual_output   => 'do_not_display')
    end
    
    should "return false when the script name is empty" do
      @invalidscriptfile.script_name = '   '
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the name is empty"
    end
    
    should "return false when the description is nil" do
      @invalidscriptfile.description = nil
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the description is nil"
    end
    
    should "return false when the max_marks is negative" do
      @invalidscriptfile.max_marks = -1
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the max_marks is negative"
    end
    
    should "return false when the max_marks is not integer" do
      @invalidscriptfile.max_marks = 49.5
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the max_marks is not integer"
    end
    
    should "return false when the display option has an invalid option" do
      @invalidscriptfile.display_description = 'display_after_due_date'
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the display option has an invalid option"
    end
    
    should "return false when the script name already exists" do
      @invalidscriptfile.script_name = 'validscript.sh'
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the script name already exists"
    end
    
    should "return false when the seq_num already exists" do
      @invalidscriptfile.seq_num = 1
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the seq_num already exists"
    end
    
  end
  
end
