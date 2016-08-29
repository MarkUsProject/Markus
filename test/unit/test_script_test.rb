require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class TestScriptTest < ActiveSupport::TestCase
  should belong_to :assignment
  should have_many :test_script_results
  
  should validate_presence_of :assignment
  
  should validate_presence_of :seq_num
  should validate_presence_of :script_name
  should validate_presence_of :max_marks
  
  # For booleans, should validate_presence_of does
  # not work: see the Rails API documentation for should validate_presence_of
  # (Model validations)
  # should validate_presence_of does not work for boolean value false.
  # Using should allow_value instead
  should allow_value(true).for(:run_by_instructors)
  should allow_value(false).for(:run_by_instructors)
  should allow_value(true).for(:run_by_students)
  should allow_value(false).for(:run_by_students)
  should allow_value(true).for(:halts_testing)
  should allow_value(false).for(:halts_testing)
  
  should validate_presence_of :display_description
  should validate_presence_of :display_run_status
  should validate_presence_of :display_marks_earned
  should validate_presence_of :display_input
  should validate_presence_of :display_expected_output
  should validate_presence_of :display_actual_output
  
  should validate_numericality_of :seq_num
  should validate_numericality_of :max_marks
  
  # create
  context "A valid script file" do
    
    setup do
      @asst = Assignment.make
      @scriptfile = TestScript.make(assignment_id:              @asst.id,
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
    
    should "return true when a valid file is created" do
      assert @scriptfile.valid?
      assert @scriptfile.save
    end
    
    should "return true when a valid file is created even if the description is empty" do
      @scriptfile.description = ''
      assert @scriptfile.valid?
      assert @scriptfile.save
    end
    
    should "return true when a valid file is created even if the max_marks is zero" do
      @scriptfile.max_marks = 0
      assert @scriptfile.valid?
      assert @scriptfile.save
    end

  end
  
  # update
  context "An invalid script file" do
    
    setup do
      @asst = Assignment.make
      display_option = %w(do_not_display display_after_submission display_after_collection)
      
      @validscriptfile = TestScript.make(assignment_id:               @asst.id,
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
                                         
      @invalidscriptfile = TestScript.make(assignment_id:             @asst.id,
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
    
    should "return false when assignment is nil" do
      @invalidscriptfile.assignment_id = nil
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when assignment is nil"
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
      @invalidscriptfile.max_marks = 0.5
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the max_marks is not integer"
    end
    
    should "return false when the script_name already exists" do
      @invalidscriptfile.script_name = 'validscript.sh'
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the script name already exists in the same assignment"
    end
    
    should "return false when the seq_num already exists" do
      @invalidscriptfile.seq_num = 1
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the seq_num already exists in the same assignment"
    end

    should "return false when the display_description option has an invalid option" do
      @invalidscriptfile.display_description = 'display_after_due_date'
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the display_description option has an invalid option"
    end
    
    should "return false when the display_run_status option has an invalid option" do
      @invalidscriptfile.display_run_status = 'display_after_submit'
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the display_run_status option has an invalid option"
    end
    
    should "return false when the display_marks_earned option has an invalid option" do
      @invalidscriptfile.display_marks_earned = 'display_before_due_date'
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the display_marks_earned option has an invalid option"
    end
    
    should "return false when the display_input option has an invalid option" do
      @invalidscriptfile.display_input = 'display_before_collection'
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the display_input option has an invalid option"
    end
    
    should "return false when the display_expected_output option has an invalid option" do
      @invalidscriptfile.display_expected_output = 'display_at_submission'
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the display_expected_output option has an invalid option"
    end
    
    should "return false when the display_actual_output option has an invalid option" do
      @invalidscriptfile.display_actual_output = 'display_at_collection'
      assert !@invalidscriptfile.valid?, "script file expected to be invalid when the display_actual_output option has an invalid option"
    end
    
  end
  
  # delete
  context "MarkUs" do
    
    setup do
      @asst = Assignment.make
      @scriptfile = TestScript.make(assignment_id:               @asst.id,
                                    seq_num:                     1,
                                    script_name:                 'script.sh',
                                    description:                 'This is a bash script file',
                                    max_marks:                   5,
                                    run_by_instructors:          true,
                                    run_by_students:             true,
                                    halts_testing:               false,
                                    display_description:         'do_not_display',
                                    display_run_status:          'do_not_display',
                                    display_marks_earned:        'do_not_display',
                                    display_input:               'do_not_display',
                                    display_expected_output:     'do_not_display',
                                    display_actual_output:       'do_not_display')
    end
    
    should "be able to delete a script file" do
      assert @scriptfile.valid?
      assert @scriptfile.destroy
    end
    
  end
  
end
