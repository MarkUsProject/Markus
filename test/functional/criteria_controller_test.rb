# encoding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__),'..', 'test_helper'))

require 'shoulda'
require 'machinist'

class CriteriaControllerTest < AuthenticatedControllerTest

  context 'An unauthenticated and unauthorized user' do

    context 'with an assignment' do
      setup do
        @grouping = Grouping.make
        @assignment = @grouping.assignment
      end

      should 'be redirected on :update_positions' do
        get :update_positions, assignment_id: @assignment.id
        assert_response :redirect
      end
    end
  end # An unauthenticated and unauthorized user doing a GET

  context 'An admin, with an assignment' do

    setup do
      @admin = Admin.make
      @assignment = Assignment.make

    end

    context 'with a criterion' do
      setup do
        @criterion = RubricCriterion.make(name: 'Algorithm',
                                          assignment: @assignment)
      end

      context 'with another criterion' do
        setup do
          @criterion2 = RubricCriterion.make(assignment: @assignment,
                                             position: 2)
        end

        should 'be able to update_positions' do
          get_as @admin,
                :update_positions,
                criterion: [@criterion2.id,
                            @criterion.id],
                assignment_id: @assignment.id
          assert render_template ''
          assert_response :success

          c1 = RubricCriterion.find(@criterion.id)
          assert_equal 1, c1.position
          c2 = RubricCriterion.find(@criterion2.id)
          assert_equal 2, c2.position
        end
      end

    end
  end # An admin, with an assignment, and a rubric criterion
end
