require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'
require 'mocha'

class RubricCriterionTest < ActiveSupport::TestCase
  fixtures :all
  set_fixture_class :rubric_criteria => RubricCriterion
  
  #Test that Criteria with no names are not valid
  def test_no_name_attr
    no_criteria_name = create_no_attr(:rubric_criterion_name)
    assert !no_criteria_name.valid?
  end
  
  # Test to make sure that Criteria have unique names within the scope of a
  # single assignment
  def test_unique_name
    # First, I assume there's a fixture generating a RubricCriterion with
    # the rubric_criteiron_name "Algorithm Design"
    original = RubricCriterion.find_by_rubric_criterion_name("Algorithm Design")
    assert_not_nil original, "Expected to have a RubricCriterion with the name Algorithm Design in the fixtures"
    
    taken_name = create_no_attr(nil)
    taken_name.rubric_criterion_name = "Algorithm Design"
    taken_name.assignment = original.assignment
    assert !taken_name.valid?    
  end
  
  # Test to make sure that Criteria can have the same names if they belong to
  # different Assignments
  def test_same_name_for_different_assignments
    # First, I assume there's a fixture generating a RubricCriterion with
    # the rubric_criteiron_name "Algorithm Design"
    original = RubricCriterion.find_by_rubric_criterion_name("Algorithm Design")
    assert_not_nil original, "Expected to have a RubricCriterion with the name Algorithm Design in the fixtures"
    
    taken_name = create_no_attr(nil)
    taken_name.rubric_criterion_name = "Algorithm Design"
    
    assignment = assignments(:assignment_2)
    assert_not_nil assignment, "Expected to find assignment_2 fixture in DB"
    
    taken_name.assignment = assignment
    assert taken_name.valid?  
  end
  
  #Test that Criteria unassigned to Assignment are NOT OK
  def test_no_assignment_id
    no_assignment_id = create_no_attr(:assignment_id)
    assert !no_assignment_id.valid?
  end
  
  #Test that Criteria without weight are NOT OK
  def test_no_weight
    no_weight = create_no_attr(:weight)
    assert !no_weight.valid?
  end
  
  #Test that Criteria assigned to non-existant Assignment
  #is NOT OK
  def test_assignment_id_dne
    assignment_id_dne = create_no_attr(nil)
    assignment_id_dne.assignment = Assignment.new
    assert !assignment_id_dne.save
  end
  
  #Test that Criteria assignment ID's can only be integers
  def test_assignment_id_int_only
    int_only = create_no_attr(nil)
    int_only.assignment_id = 'string'
    assert !int_only.valid?
    
    int_only.assignment_id = '0.1'
    assert !int_only.valid?
    
    int_only.assignment_id = 0.1
    assert !int_only.valid?
    
    int_only.assignment_id = -1
    assert !int_only.valid?
    
  end
  
  # Weights are restricted to a decimal value greater than 0
  def test_bad_weight_range
    # create valid assignment first
    a = assignments(:assignment_6)
    assert a.valid? # should be valid now
    weight_range = create_no_attr(:assignment_id)
    
    assert !weight_range.valid? # missing assignment association
    weight_range.assignment = a
    assert weight_range.valid? # should be valid now
    
    weight_range.weight = 'string'
    assert !weight_range.valid?, "weight is a string, it shouldn't be valid"
    
    weight_range.weight = -0.1
    assert !weight_range.valid?, "weight is negative, it shouldn't be valid"
    
    weight_range.weight = 0.0
    assert !weight_range.valid?, "weight is zero, it shouldn't be valid"
    
    weight_range.weight = 100.0
    assert weight_range.valid?, "weight is fine, it should be valid"
    
    weight_range.weight = 0.5
    assert weight_range.valid?, "weight is fine, it should be valid"
  end
  
  # Helper method for test_validate_presence_of to create a criterion without 
  # the specified attribute. if attr == nil then all attributes are included
  def create_no_attr(attr)
    new_rubric_criteria = { 
      :rubric_criterion_name => 'somecriteria',
      :assignment_id => Assignment.find(:first).id, 
      :weight => 0.25,
      :level_0_name => 'Horrible',
      :level_1_name => 'Poor',
      :level_2_name => 'Satisfactory',
      :level_3_name => 'Good',
      :level_4_name => 'Excellent'
    }
    
    new_rubric_criteria.delete(attr) if attr
    return RubricCriterion.new(new_rubric_criteria)
  end
  
  def test_mark_for
    result = results(:result_1)
    rubric = rubric_criteria(:c4)
    assert_not_nil rubric.mark_for(result.id)
  end
  
  def test_set_default_levels_1
    r = RubricCriterion.new
    assert r.set_default_levels
  end
  
  def test_set_default_levels_2
    r = RubricCriterion.new
    r.set_default_levels
    r.save
    assert_equal("Very Poor", r.level_0_name)
    assert_equal("Weak", r.level_1_name)
    assert_equal("Passable", r.level_2_name)
    assert_equal("Good", r.level_3_name)
    assert_equal("Excellent", r.level_4_name)
  end
  
  should "be able to set all the level names at once" do
    r = RubricCriterion.new
    levels = []
    0.upto(RubricCriterion::RUBRIC_LEVELS - 1) do |i|
      levels << 'l' + i.to_s()
    end
    r.expects(:save).once
    r.set_level_names(levels)
    0.upto(RubricCriterion::RUBRIC_LEVELS - 1) do |i|
      assert_equal r['level_' + i.to_s() + '_name'], 'l' + i.to_s()
    end
  end
  
  context "from an assignment composed of rubric criteria" do
    setup do
      @csv_string = "Algorithm Design,2.0,Horrible,Poor,Satisfactory,Good,Excellent,,,,,
Documentation,2.7,Horrible,Poor,Satisfactory,Good,Excellent,,,,,
Testing,2.2,Horrible,Poor,Satisfactory,Good,Excellent,,,,,
Correctness,2.0,Horrible,Poor,Satisfactory,Good,Excellent,,,,,\n"
      @assignment = assignments(:assignment_1)
    end
    
    should "be able to get a CSV string" do
      s = RubricCriterion.create_csv(@assignment)
      assert_equal @csv_string, s
    end
    
    should "be able to use a generated string for parsing" do
      csv_string = RubricCriterion.create_csv(@assignment)
      tempfile = Tempfile.new('rubric_csv')
      tempfile << csv_string
      tempfile.rewind
      invalid_lines = []
      dst_assignment = assignments(:assignment_3)
      nb_updates = RubricCriterion.parse_csv(tempfile, dst_assignment, invalid_lines)
      assert_equal 4, nb_updates
      assert_equal 0, invalid_lines.size
      dst_assignment.reload
      assert_equal 4, dst_assignment.rubric_criteria.size
    end
  end
  
  context "from an assignment composed of rubric criteria with commas and quotes in the descriptions" do
    setup do
      @csv_string = "Part 1 Programming,2.0,Horrible,Poor,Satisfactory,Good,Excellent,\"Makes the TA \"\"Shivers\"\"\",\"Leaves the TA \"\"calm\"\"\",\"Makes the TA \"\"grin\"\"\",\"Makes the TA \"\"smile\"\"\",\"Makes, the, TA scream: \"\"at last, it was about time\"\"\"
Part 2 Programming,2.0,Horrible,Poor,Satisfactory,Good,Excellent,,,,,\n"
      @assignment = assignments(:assignment_2)
    end
    
    should "be able to get a CSV string" do
      s = RubricCriterion.create_csv(@assignment)
      assert_equal @csv_string, s
    end
    
    should "be able to use a generated string for parsing" do
      csv_string = RubricCriterion.create_csv(@assignment)
      tempfile = Tempfile.new('rubric_csv')
      tempfile << csv_string
      tempfile.rewind
      invalid_lines = []
      dst_assignment = assignments(:assignment_3)
      nb_updates = RubricCriterion.parse_csv(tempfile, dst_assignment, invalid_lines)
      assert_equal 2, nb_updates
      assert_equal 0, invalid_lines.size
      dst_assignment.reload
      assert_equal 2, dst_assignment.rubric_criteria.size
    end
  end
  
  context "from an assignment without criteria" do
    setup do
      @assignment = assignments(:assignment_3)
    end
    
    should "be able to get an empty CSV string" do
      csv_string = RubricCriterion.create_csv(@assignment)
      assert_equal "", csv_string
    end
  end
  
  context "when parsing a CSV file" do
    
    should "raise an error message on an empty row" do
      e = assert_raise RuntimeError do
        RubricCriterion.create_or_update_from_csv_row([], Assignment.new)
      end
      assert_equal I18n.t('criteria_csv_error.incomplete_row'), e.message 
    end
    
    should "raise an error message on a 1 element row" do
      e = assert_raise RuntimeError do
        RubricCriterion.create_or_update_from_csv_row(['name'], Assignment.new)
      end
      assert_equal I18n.t('criteria_csv_error.incomplete_row'), e.message 
    end
    
    should "raise an error message on a 2 element row" do
      e = assert_raise RuntimeError do
        RubricCriterion.create_or_update_from_csv_row(['name', '1.0'], Assignment.new)
      end
      assert_equal I18n.t('criteria_csv_error.incomplete_row'), e.message 
    end
    
    should "raise an error message on a row with any number of elements that does not include a name for every criterion" do
      row = ['name', '1.0']
      (0..RubricCriterion::RUBRIC_LEVELS - 2).each do |i|
        row << 'name' + i.to_s
          e = assert_raise RuntimeError do
            RubricCriterion.create_or_update_from_csv_row(row, Assignment.new)
          end
          assert_equal I18n.t('criteria_csv_error.incomplete_row'), e.message 
      end
    end
    
    should "raise an error message on a row with an invalid weight" do
      row = ['name', 'weight', 'l0', 'l1', 'l2', 'l3', 'l4']
      e = assert_raise RuntimeError do
        RubricCriterion.create_or_update_from_csv_row(row, Assignment.new)
      end
      assert_equal I18n.t('criteria_csv_error.weight_zero'), e.message
    end
    
    should "raise the errors hash in case of an unpredicted error" do
      e = assert_raise RuntimeError do
        # That should fail because the assignment doesn't yet exists (in the DB)
        RubricCriterion.create_or_update_from_csv_row(['name', 10, 'l0', 'l1', 'l2', 'l3', 'l4'], Assignment.new)
      end
      assert_instance_of ActiveRecord::Errors, e.message
    end
    
    context "and the row is valid" do
      
      setup do
        # we'll need a valid assignment for those cases.
        @assignment = assignments(:assignment_1)
        # and a valid csv row...
        row = ['criterion 5', '1.0']
        (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
          row << 'name' + i.to_s
        end
        # ...containing commas and quotes in the descriptions
        (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
          row << 'description' + i.to_s + ' with comma (,) and ""quotes""'
        end
        @csv_base_row = row
      end
      
      should "be able to create a new instance without level descriptions" do
        criterion = RubricCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
        assert_not_nil criterion
        assert_instance_of RubricCriterion, criterion
        assert_equal criterion.assignment, @assignment
        (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
          assert_equal 'name' + i.to_s, criterion['level_' + i.to_s + '_name']
        end
      end
      
      context "and there is an existing rubric criterion with the same name" do
        setup do
          criterion = RubricCriterion.new
          criterion.set_default_levels
          # 'criterion 5' is the name used in the criterion held
          # in @csv_base_row - but they use different level names/descriptions.
          # I'll use the defaults here, and see if I can overwrite with
          # @csv_base_row.
          criterion.rubric_criterion_name = 'criterion 5'
          criterion.assignment = @assignment
          criterion.position = @assignment.next_criterion_position
          criterion.weight = 5.0
          assert criterion.save
        end
        should "allow a criterion with the same name to overwrite" do
          assert_nothing_raised do
            criterion = RubricCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
            (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
              assert_equal 'name' + i.to_s, criterion['level_' + i.to_s + '_name']
            end
            assert_equal 1.0, criterion.weight
          end
          
        end
      end
      
      should "be able to create a new instance with level descriptions" do
        (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
          @csv_base_row << 'description' + i.to_s
        end
        criterion = RubricCriterion.create_or_update_from_csv_row(@csv_base_row, @assignment)
        assert_not_nil criterion
        assert_instance_of RubricCriterion, criterion
        assert_equal criterion.assignment, @assignment
        (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
          assert_equal 'name' + i.to_s, criterion['level_' + i.to_s + '_name']
          assert_equal 'description' + i.to_s + ' with comma (,) and ""quotes""',
                       criterion['level_' + i.to_s + '_description']
        end
      end
      
    end

  end

  should "be able to parse a valid CSV file" do
    tempfile = Tempfile.new('rubric_criteria_csv')
    tempfile << "criterion 6,1.0,l0,l1,l2,l3,l4,d0,d1,d2,d3,d4\n"
    tempfile.rewind
    assignment = assignments(:assignment_3)
    invalid_lines = []
    
    nb_updates = RubricCriterion.parse_csv(tempfile, assignment, invalid_lines)
    assert_equal nb_updates, 1
    assert invalid_lines.empty?
  end
  
  should "report errors on a invalid CSV file" do
    tempfile = Tempfile.new('flexible_criteria_csv')
    tempfile << "criterion 6\n,criterion 7\n"
    tempfile.rewind
    assignment = assignments(:assignment_3)
    invalid_lines = []
    
    nb_updates = RubricCriterion.parse_csv(tempfile, assignment, invalid_lines)
    assert_equal 0, nb_updates
    assert_equal 2, invalid_lines.length
  end
  
end
