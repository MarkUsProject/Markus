require 'spec_helper'

RSpec.describe CriteriaController, type: :controller do

  describe 'Using Flexible Criteria' do

    describe 'An unauthenticated and unauthorized user doing a GET' do
      context '#index' do
        it 'should respond with redirect' do
          get :index, assignment_id: 1
          is_expected.to respond_with :redirect
        end
      end

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

      context '#update' do
        it 'should respond with redirect' do
          put :update, assignment_id: 1, id: 1
          is_expected.to respond_with :redirect
        end
      end

      context '#destroy' do
        it 'should respond with redirect' do
          delete :destroy, assignment_id: 1, id: 1
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

      context '#download_yml' do
        it 'should respond with redirect' do
          get :download_yml, assignment_id: 1
          is_expected.to respond_with :redirect
        end
      end
    end

    describe 'An unauthenticated and unauthorized user doing a POST' do
      context '#index' do
        it 'should respond with redirect' do
          post :index, assignment_id: 1
          is_expected.to respond_with :redirect
        end
      end

      context '#new' do
        it 'should respond with redirect' do
          post :new, assignment_id: 1
          is_expected.to respond_with :redirect
        end
      end

      context '#update' do
        it 'should respond with redirect' do
          put :update, assignment_id: 1, id: 1
          is_expected.to respond_with :redirect
        end
      end

      context '#edit' do
        it 'should respond with redirect' do
          post :edit, assignment_id: 1, id: 1
          is_expected.to respond_with :redirect
        end
      end

      context '#destroy' do
        it 'should respond with redirect' do
          delete :destroy, assignment_id: 1, id: 1
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

      context '#index' do
        before(:each) do
          get_as @admin, :index, assignment_id: @assignment.id
        end
        it 'should respond assign assignment and criteria' do
          expect(assigns(:assignment)).to be_truthy
          expect(assigns(:criteria)).to be_truthy
        end

        it 'should render the edit template' do
          is_expected.to render_template(:index)
        end

        it 'should respond with success' do
          is_expected.to respond_with(:success)
        end
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
          expect(assigns(:criterion)).to be_truthy
        end

        it 'should render edit template' do
          is_expected.to render_template(:edit)
        end

        it 'should respond with success' do
          is_expected.to respond_with(:success)
        end
      end

      context '#update' do
        context 'with errors' do
          before(:each) do
            expect_any_instance_of(FlexibleCriterion)
                .to receive(:save).and_return(false)
            expect_any_instance_of(FlexibleCriterion)
                .to receive(:errors).and_return('')

            get_as @admin,
                   :update,
                   format:             :js,
                   assignment_id:      1,
                   id:                 @criterion.id,
                   flexible_criterion: { name: 'one', max_mark: 10 },
                   criterion_type:     'FlexibleCriterion'
          end

          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
          end

          it 'should render the errors template' do
            is_expected.to render_template('errors')
          end

          it 'should respond with success' do
            is_expected.to respond_with(:success)
          end
        end

        context 'without errors' do
          before(:each) do
            get_as @admin,
                   :update,
                   format:             :js,
                   assignment_id:      1,
                   id:                 @criterion.id,
                   flexible_criterion: { name: 'one', max_mark: 10 },
                   criterion_type:     'FlexibleCriterion'
            assert flash[:success], I18n.t('criterion_saved_success')
          end

          it 'successfully assign criterion' do
            expect(assigns(:criterion)).to be_truthy
          end

          it 'should render the update template' do
            is_expected.to render_template(:update)
          end
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

      context '#index' do
        before(:each) do
          post_as @admin, :index, assignment_id: @assignment.id
        end
        it 'should respond with appropriate content' do
          expect(assigns(:assignment)).to be_truthy
          expect(assigns(:criteria)).to be_truthy
        end

        it 'should render the index template' do
          is_expected.to render_template(:index)
        end

        it 'should respond with success' do
          is_expected.to respond_with(:success)
        end
      end

      context '#create' do
        context 'with save error' do
          before(:each) do
            @errors = ActiveModel::Errors.new(self)
            @errors['message'] = 'error message'
            expect_any_instance_of(FlexibleCriterion)
                .to receive(:save).and_return(false)
            expect_any_instance_of(FlexibleCriterion)
                .to receive(:errors).and_return(@errors)
            post_as @admin,
                    :create,
                    format:               :js,
                    assignment_id:        @assignment.id,
                    flexible_criterion:   { name: 'first',
                                            max_mark: 10 },
                    new_criterion_prompt: 'first',
                    criterion_type:       'FlexibleCriterion'
          end
          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
            expect(assigns(:errors)).to be_truthy
            expect(assigns(:assignment)).to be_truthy
          end

          it 'should render the add_criterion_error template' do
            is_expected
                .to render_template(:'criteria/add_criterion_error')
          end

          it 'should respond with success' do
            is_expected.to respond_with(:success)
          end
        end

        context 'without error on an assignment as the first criterion' do
          before(:each) do
            post_as @admin,
                    :create,
                    format:               :js,
                    assignment_id:        @assignment.id,
                    flexible_criterion:   { name: 'first',
                                            max_mark: 10 },
                    new_criterion_prompt: 'first',
                    criterion_type:       'FlexibleCriterion'
          end
          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
            expect(assigns(:assignment)).to be_truthy
          end
          it 'should render the create_and_edit template' do
            is_expected.to render_template(:'criteria/create_and_edit')
          end

          it 'should respond with success' do
            is_expected.to respond_with(:success)
          end
        end

        context 'without error on an assignment that already has criteria' do
          before(:each) do
            post_as @admin,
                    :create,
                    format:               :js,
                    assignment_id:        @assignment.id,
                    flexible_criterion:   { name: 'first',
                                            max_mark: 10 },
                    new_criterion_prompt: 'first',
                    criterion_type:       'FlexibleCriterion'
          end
          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
            expect(assigns(:assignment)).to be_truthy
          end
          it 'should render the create_and_edit template' do
            is_expected.to render_template(:'criteria/create_and_edit')
          end

          it 'should respond with success' do
            is_expected.to respond_with(:success)
          end
        end
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
                criterion:         ["#{@criterion2.class} #{@criterion2.id}", "#{@criterion.class} #{@criterion.id}"],
                assignment_id:     @assignment.id
        is_expected.to render_template('criteria/update_positions')
        is_expected.to respond_with(:success)

        c1 = FlexibleCriterion.find(@criterion.id)
        expect(c1.position).to eql(2)
        c2 = FlexibleCriterion.find(@criterion2.id)
        expect(c2.position).to eql(1)
      end
    end

    describe 'An authenticated and authorized admin doing a DELETE' do
      before(:each) do
        @admin = create(:admin)
        @assignment = create(:flexible_assignment)
        @criterion = create(:flexible_criterion,
                            assignment: @assignment)
      end

      it ' should be able to delete the criterion' do
        delete_as @admin,
                  :destroy,
                  format:         :js,
                  assignment_id:  1,
                  id:             @criterion.id,
                  criterion_type: @criterion.class.to_s
        expect(assigns(:criterion)).to be_truthy
        expect([I18n.t('criterion_deleted_success')]).to eql(flash[:success])
        is_expected.to respond_with(:success)

        expect { FlexibleCriterion.find(@criterion.id) }
            .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end # Tests using Flexible Criteria

  describe 'Using Rubric Criteria' do

    describe 'An unauthenticated and unauthorized user doing a GET' do
      context '#index' do
        it 'should respond with redirect' do
          get :index, assignment_id: 1
          is_expected.to respond_with :redirect
        end
      end

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

      context '#destroy' do
        it 'should respond with redirect' do
          delete :destroy, assignment_id: 1, id: 1
          is_expected.to respond_with :redirect
        end
      end

      context '#update' do
        it 'should respond with redirect' do
          put :update, assignment_id: 1, id: 1
          is_expected.to respond_with :redirect
        end
      end

      context '#update_positions' do
        it 'should respond with redirect' do
          get :update_positions, assignment_id: 1
          is_expected.to respond_with :redirect
        end
      end

      context '#download_yml' do
        it 'should respond with redirect' do
          get :download_yml, assignment_id: 1
          is_expected.to respond_with :redirect
        end
      end
    end

    describe 'An unauthenticated and unauthorized user doing a POST' do
      context '#index' do
        it 'should respond with redirect' do
          post :index, assignment_id: 1
          is_expected.to respond_with :redirect
        end
      end

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

      context '#update' do
        it 'should respond with redirect' do
          put :update, assignment_id: 1, id: 1
          is_expected.to respond_with :redirect
        end
      end

      context '#destroy' do
        it 'should respond with redirect' do
          delete :destroy, assignment_id: 1, id: 1
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

      context '#index' do
        before(:each) do
          get_as @admin, :index, assignment_id: @assignment.id
        end
        it 'should respond assign assignment and criteria' do
          expect(assigns(:assignment)).to be_truthy
          expect(assigns(:criteria)).to be_truthy
        end

        it 'should render the edit template' do
          is_expected.to render_template(:index)
        end

        it 'should respond with success' do
          is_expected.to respond_with(:success)
        end
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
          expect(assigns(:criterion)).to be_truthy
        end

        it 'should render edit template' do
          is_expected.to render_template(:edit)
        end

        it 'should respond with success' do
          is_expected.to respond_with(:success)
        end
      end

      context '#update' do
        context 'with errors' do
          before(:each) do
            expect_any_instance_of(RubricCriterion)
                .to receive(:save).and_return(false)
            expect_any_instance_of(RubricCriterion)
                .to receive(:errors).and_return('')

            get_as @admin,
                   :update,
                   format:           :js,
                   assignment_id:    1,
                   id:               @criterion.id,
                   rubric_criterion: { name: 'one', max_mark: 10 },
                   criterion_type:   'RubricCriterion'
          end

          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
          end

          it 'should render the errors template' do
            is_expected.to render_template('errors')
          end

          it 'should respond with success' do
            is_expected.to respond_with(:success)
          end
        end

        context 'without errors' do
          before(:each) do
            get_as @admin,
                   :update,
                   format:           :js,
                   assignment_id:    1,
                   id:               @criterion.id,
                   rubric_criterion: { name: 'one', max_mark: 10 },
                   criterion_type:   'RubricCriterion'
            assert flash[:success], I18n.t('criterion_saved_success')
          end

          it 'successfully assign criterion' do
            expect(assigns(:criterion)).to be_truthy
          end

          it 'should render the update template' do
            is_expected.to render_template(:update)
          end
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

      context '#index' do
        before(:each) do
          post_as @admin, :index, assignment_id: @assignment.id
        end
        it 'should respond with appropriate content' do
          expect(assigns(:assignment)).to be_truthy
          expect(assigns(:criteria)).to be_truthy
        end

        it 'should render the index template' do
          is_expected.to render_template(:index)
        end

        it 'should respond with success' do
          is_expected.to respond_with(:success)
        end
      end

      context '#create' do
        context 'with save error' do
          before(:each) do
            @errors = ActiveModel::Errors.new(self)
            @errors['message'] = 'error message'
            expect_any_instance_of(RubricCriterion)
                .to receive(:save).and_return(false)
            expect_any_instance_of(RubricCriterion)
                .to receive(:errors).and_return(@errors)
            post_as @admin,
                    :create,
                    format:               :js,
                    assignment_id:        @assignment.id,
                    rubric_criterion:     { name: 'first',
                                           max_mark: 10 },
                    new_criterion_prompt: 'first',
                    criterion_type:       'RubricCriterion'
          end
          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
            expect(assigns(:errors)).to be_truthy
            expect(assigns(:assignment)).to be_truthy
          end

          it 'should render the add_criterion_error template' do
            is_expected
                .to render_template(:'criteria/add_criterion_error')
          end

          it 'should respond with success' do
            is_expected.to respond_with(:success)
          end
        end

        context 'without error on an assignment as the first criterion' do
          before(:each) do
            post_as @admin,
                    :create,
                    format:               :js,
                    assignment_id:        @assignment.id,
                    rubric_criterion:     { name: 'first',
                                            max_mark: 10 },
                    new_criterion_prompt: 'first',
                    criterion_type:       'RubricCriterion'
          end
          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
            expect(assigns(:assignment)).to be_truthy
          end
          it 'should render the create_and_edit template' do
            is_expected.to render_template(:'criteria/create_and_edit')
          end

          it 'should respond with success' do
            is_expected.to respond_with(:success)
          end
        end

        context 'without error on an assignment that already has criteria' do
          before(:each) do
            post_as @admin,
                    :create,
                    format:               :js,
                    assignment_id:        @assignment.id,
                    rubric_criterion:     { name: 'first',
                                            max_mark: 10 },
                    new_criterion_prompt: 'first',
                    criterion_type:       'RubricCriterion'
          end
          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
            expect(assigns(:assignment)).to be_truthy
          end
          it 'should render the create_and_edit template' do
            is_expected.to render_template(:'criteria/create_and_edit')
          end

          it 'should respond with success' do
            is_expected.to respond_with(:success)
          end
        end
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
                criterion:         ["#{@criterion2.class} #{@criterion2.id}", "#{@criterion.class} #{@criterion.id}"],
                assignment_id:     @assignment.id
        is_expected.to render_template('criteria/update_positions')
        is_expected.to respond_with(:success)

        c1 = RubricCriterion.find(@criterion.id)
        expect(c1.position).to eql(2)
        c2 = RubricCriterion.find(@criterion2.id)
        expect(c2.position).to eql(1)
      end
    end

    describe 'An authenticated and authorized admin doing a DELETE' do
      before(:each) do
        @admin = create(:admin)
        @assignment = create(:rubric_assignment)
        @criterion = create(:rubric_criterion,
                            assignment: @assignment)
      end

      it ' should be able to delete the criterion' do
        delete_as @admin,         :destroy,
                  format:         :js,
                  assignment_id:  1,
                  id:             @criterion.id,
                  criterion_type: @criterion.class.to_s
        expect(assigns(:criterion)).to be_truthy
        expect([I18n.t('criterion_deleted_success')]).to eql(flash[:success])
        is_expected.to respond_with(:success)

        expect { RubricCriterion.find(@criterion.id) }
            .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end # Tests using Rubric Criteria
end

