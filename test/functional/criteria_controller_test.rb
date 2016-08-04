# encoding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__),'..', 'test_helper'))

require 'shoulda'
require 'machinist'

class CriteriaControllerTest < AuthenticatedControllerTest

  context 'An admin, with an assignment' do

    setup do
      @admin =      Admin.make
      @assignment = Assignment.make

    end

    should 'upload successfully well formatted yml criteria' do
      yml_string = <<END
cr1:
  weight: 5
  level_0:
    name: what?
    description: fail
  level_1:
    name: hmm
    description: almost fail
  level_2:
    name: average
    description: average joe
  level_3:
    name: good
    description: alright
  level_4:
    name: poor
    description: I expected more
cr2:
  weight: 2
END
      post_as @admin,
              :upload_yml,
              assignment_id: @assignment.id,
              yml_upload:    {rubric: yml_string}

      assert_response :redirect
      assert_not_nil set_flash.to(t('criteria.upload.success',
                                    nb_updates: 2))
      @assignment.reload
      cr1 = @assignment.get_criteria(:all, :rubric).find_by(name: 'cr1')
      cr2 = @assignment.get_criteria(:all, :rubric).find_by(name: 'cr2')
      assert_equal(@assignment.get_criteria(:all, :rubric).size, 2)
      assert_equal(8, cr2.max_mark) # We get four times what we entered because we entered the weight
      assert_equal(20, cr1.max_mark)
      assert_equal('what?', cr1.level_0_name)
      assert_equal('fail', cr1.level_0_description)
      assert_equal('hmm', cr1.level_1_name)
      assert_equal('almost fail', cr1.level_1_description)
      assert_equal('average', cr1.level_2_name)
      assert_equal('average joe', cr1.level_2_description)
      assert_equal('good', cr1.level_3_name)
      assert_equal('alright', cr1.level_3_description)
      assert_equal('poor', cr1.level_4_name)
      assert_equal('I expected more', cr1.level_4_description)
    end

    should 'deal with bad weight on yaml file' do
      post_as @admin,
              :upload_yml,
              assignment_id: @assignment.id,
              yml_upload:    { rubric: "cr1:\n  weight: monstrously heavy\n" }

      assert_response  :redirect
      assert_not_nil set_flash.to(
        t('criteria.upload.error') + ' cr1')
      @assignment.reload
      new_categories_list = @assignment.annotation_categories
      assert_equal [], @assignment.get_criteria(:all, :rubric)

    end

    should 'deal properly with yml syntax error' do
     post_as @admin,
             :upload_yml,
             assignment_id: @assignment.id,
             yml_upload:    { rubric: "cr1:\n  weight: 5\na" }

      assert_response :redirect
      assert_not_nil set_flash.to(t('criteria.upload.error') + '  ' +
                                  t('criteria.upload.syntax_error',
                                    error: "syntax error on line 2, col 1: `'"))
      @assignment.reload
      new_categories_list = @assignment.annotation_categories
      assert_equal(@assignment.get_criteria(:all, :rubric).size, 0)
    end

    should 'deal properly with empty yml file' do
      post_as @admin,
              :upload_yml,
              assignment_id: @assignment.id,
              yml_upload:    { rubric: '' }
      assert_response :redirect
      @assignment.reload
      new_categories_list = @assignment.annotation_categories
      assert_equal(@assignment.get_criteria(:all, :rubric).size, 0)

    end

    context 'with a criterion' do
      setup do
        @criterion = RubricCriterion.make(name: 'Algorithm',
                                          assignment: @assignment)
      end

      should 'upload yml file without deleting preexisting criteria' do
        post_as @admin,
                :upload_yml,
                assignment_id: @assignment.id,
                yml_upload:    { rubric: "cr1:\n  weight: 5\ncr2:\n  weight: 2\n" }


        assert_response :redirect
        assert set_flash.to(t('criteria.upload.success',
                              nb_updates: 2))
        @assignment.reload
        assert_equal(@assignment.get_criteria(:all, :rubric).size, 3)
        assert_equal(@assignment.get_criteria[0].max_mark, 4.0)
      end

    end
  end # An admin, with an assignment, and a rubric criterion
end
