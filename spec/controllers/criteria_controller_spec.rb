require 'spec_helper'

RSpec.describe CriteriaController, type: :controller do

  describe 'Using Rubric criteria' do

    describe 'An unauthenticated and unauthorized user doing a GET' do
      context '#new' do
        it 'should respond with redirect' do
          get :new, assignment_id: 1
          is_expected.to respond_with :redirect
        end
      end

      context '#edit' do
        it 'should respond with redirect' do
          get :edit, assignment_id: 1, id: 1
          is_expected.to respond_with :redirect
        end
      end

      context 'with an assignment' do
        before :each do
          @grouping = FactoryGirl.create(:grouping)
          @assignment = @grouping.assignment
        end

        context 'and a submission' do
          before :each do
            @submission = create(:submission, grouping: @grouping)
          end

          context '#edit' do
            it 'should respond with redirect' do
              get :edit,
                  assignment_id: @assignment.id,
                  submission_id: @submission.id,
                  id:            1
              is_expected.to respond_with :redirect
            end
          end
        end
      end

      context '#update_positions' do
        it 'should respond with redirect' do
          get :update_positions, assignment_id: 1
          is_expected.to respond_with :redirect
        end
      end
    end

    describe 'An unauthenticated and unauthorized user doing a POST' do
      context '#new' do
        it 'should respond with redirect' do
          post :new, assignment_id: 1
          is_expected.to respond_with :redirect
        end
      end

      context '#edit' do
        it 'should respond with redirect' do
          post :edit, assignment_id: 1, id: 1
          is_expected.to respond_with :redirect
        end
      end
    end

    describe 'An authenticated and authorized admin doing a GET' do
      before(:each) do
        @admin = create(:admin)
        @assignment = create(:rubric_assignment)
        @criterion = create(:rubric_criterion,
                            assignment: @assignment,
                            position: 1,
                            name: 'criterion1')
        @criterion2 = create(:rubric_criterion,
                             assignment: @assignment,
                             position: 2,
                             name: 'criterion2')
        @criterion3 = create(:rubric_criterion,
                             assignment: @assignment,
                             position: 3,
                             name: 'criterion3',
                             max_mark: 1.6)
      end

      context '#new' do
        before(:each) do
          get_as @admin,
                 :new,
                 format:         :js,
                 assignment_id:  @assignment.id,
                 criterion_type: 'RubricCriterion'
        end

        it 'should respond with appropriate content' do
          expect(assigns(:assignment)).to be_truthy
          expect(assigns(:criterion_type)).to be_truthy
        end

        it 'should render the new template' do
          is_expected.to render_template(:new)
        end

        it 'should respond with success' do
          is_expected.to respond_with(:success)
        end
      end

      context '#edit' do
        before(:each) do
          get_as @admin,
                 :edit,
                 format:         :js,
                 assignment_id:  1,
                 id:             @criterion.id,
                 criterion_type: @criterion.class.to_s
        end

        it 'should respond with appropriate content' do
          expect(assigns(:criterion_type)).to be_truthy
          expect(assigns(:criterion)).to be_truthy
        end

        it 'should render edit template' do
          is_expected.to render_template(:edit)
        end

        it 'should respond with success' do
          is_expected.to respond_with(:success)
        end
      end
    end

    describe 'An authenticated and authorized admin doing a POST' do
      before(:each) do
        @admin = create(:admin, user_name: 'olm_admin')
        @assignment = create(:rubric_assignment)
        @criterion = create(:rubric_criterion,
                            assignment: @assignment,
                            position: 1,
                            name: 'criterion1')
        @criterion2 = create(:rubric_criterion,
                             assignment: @assignment,
                             position: 2,
                             name: 'criterion2')
        @criterion3 = create(:rubric_criterion,
                             assignment: @assignment,
                             position: 3,
                             name: 'criterion3',
                             max_mark: 1.6)
      end

      context '#edit' do
        before(:each) do
          post_as @admin,
                  :edit,
                  format:         :js,
                  assignment_id:  1,
                  id:             @criterion.id,
                  criterion_type: @criterion.class.to_s
        end

        it ' should respond with appropriate content' do
          expect(assigns(:criterion_type)).to be_truthy
          expect(assigns(:criterion)).to be_truthy
        end

        it 'should render the edit template' do
          is_expected.to render_template(:edit)
        end

        it 'should respond with success' do
          is_expected.to respond_with(:success)
        end
      end

      it 'should be able to update_positions' do
        post_as @admin,
                :update_positions,
                format:            :js,
                criterion:         [@criterion2.id, @criterion.id],
                assignment_id:     @assignment.id
        is_expected.to render_template('criteria/update_positions')
        is_expected.to respond_with(:success)

        c1 = RubricCriterion.find(@criterion.id)
        expect(c1.position).to eql(2)
        c2 = RubricCriterion.find(@criterion2.id)
        expect(c2.position).to eql(1)
      end
    end
  end # Tests using Rubric Criteria

  describe 'Using Flexible criteria' do

    describe 'An unauthenticated and unauthorized user doing a GET' do
      context '#new' do
        it 'should respond with redirect' do
          get :new, assignment_id: 1
          is_expected.to respond_with :redirect
        end
      end

      context '#edit' do
        it 'should respond with redirect' do
          get :edit, assignment_id: 1, id: 1
          is_expected.to respond_with :redirect
        end
      end

      context '#update_positions' do
        it 'should respond with redirect' do
          get :update_positions, assignment_id: 1
          is_expected.to respond_with :redirect
        end
      end

      context 'with an assignment' do
        before :each do
          @grouping = FactoryGirl.create(:grouping)
          @assignment = @grouping.assignment
        end

        context 'and a submission' do
          before :each do
            @submission = create(:submission, grouping: @grouping)
          end

          context '#edit' do
            it 'should respond with redirect' do
              get :edit,
                  assignment_id: @assignment.id,
                  submission_id: @submission.id,
                  id:            1
              is_expected.to respond_with :redirect
            end
          end
        end
      end
    end

    describe 'An unauthenticated and unauthorized user doing a POST' do
      context '#new' do
        it 'should respond with redirect' do
          post :new, assignment_id: 1
          is_expected.to respond_with :redirect
        end
      end

      context '#edit' do
        it 'should respond with redirect' do
          post :edit, assignment_id: 1, id: 1
          is_expected.to respond_with :redirect
        end
      end
    end

    describe 'An authenticated and authorized admin doing a GET' do
      before(:each) do
        @admin = create(:admin)
        @assignment = create(:flexible_assignment)
        @criterion = create(:flexible_criterion,
                            assignment: @assignment,
                            position: 1,
                            name: 'criterion1',
                            description: 'description1, for criterion 1')
        @criterion2 = create(:flexible_criterion,
                             assignment: @assignment,
                             position: 2,
                             name: 'criterion2',
                             description: 'description2, "with quotes"')
        @criterion3 = create(:flexible_criterion,
                             assignment: @assignment,
                             position: 3,
                             name: 'criterion3',
                             description: 'description3!',
                             max_mark: 1.6)
      end

      context '#new' do
        before(:each) do
          get_as @admin,
                 :new,
                 format:         :js,
                 assignment_id:  @assignment.id,
                 criterion_type: 'FlexibleCriterion'
        end

        it 'should respond with appropriate content' do
          expect(assigns(:assignment)).to be_truthy
          expect(assigns(:criterion_type)).to be_truthy
        end

        it 'should render the new template' do
          is_expected.to render_template(:new)
        end

        it 'should respond with success' do
          is_expected.to respond_with(:success)
        end
      end

      context '#edit' do
        before(:each) do
          get_as @admin,
                 :edit,
                 format:         :js,
                 assignment_id:  1,
                 id:             @criterion.id,
                 criterion_type: @criterion.class.to_s
        end

        it 'should respond with appropriate content' do
          expect(assigns(:criterion_type)).to be_truthy
          expect(assigns(:criterion)).to be_truthy
        end

        it 'should render edit template' do
          is_expected.to render_template(:edit)
        end

        it 'should respond with success' do
          is_expected.to respond_with(:success)
        end
      end
    end

    describe 'An authenticated and authorized admin doing a POST' do
      before(:each) do
        @admin = create(:admin, user_name: 'olm_admin')
        @assignment = create(:flexible_assignment)
        @criterion = create(:flexible_criterion,
                            assignment: @assignment,
                            position: 1,
                            name: 'criterion1',
                            description: 'description1, for criterion 1')
        @criterion2 = create(:flexible_criterion,
                             assignment: @assignment,
                             position: 2,
                             name: 'criterion2',
                             description: 'description2, "with quotes"')
        @criterion3 = create(:flexible_criterion,
                             assignment: @assignment,
                             position: 3,
                             name: 'criterion3',
                             description: 'description3!',
                             max_mark: 1.6)
      end

      context '#edit' do
        before(:each) do
          post_as @admin,
                  :edit,
                  format:         :js,
                  assignment_id:  1,
                  id:             @criterion.id,
                  criterion_type: @criterion.class.to_s
        end

        it ' should respond with appropriate content' do
          expect(assigns(:criterion_type)).to be_truthy
          expect(assigns(:criterion)).to be_truthy
        end

        it 'should render the edit template' do
          is_expected.to render_template(:edit)
        end

        it 'should respond with success' do
          is_expected.to respond_with(:success)
        end
      end

      it 'should be able to update_positions' do
        post_as @admin,
                :update_positions,
                format:            :js,
                criterion:         [@criterion2.id, @criterion.id],
                assignment_id:     @assignment.id
        is_expected.to render_template('criteria/update_positions')
        is_expected.to respond_with(:success)

        c1 = FlexibleCriterion.find(@criterion.id)
        expect(c1.position).to eql(2)
        c2 = FlexibleCriterion.find(@criterion2.id)
        expect(c2.position).to eql(1)
      end
    end
  end # Tests using Flexible Criteria
end

