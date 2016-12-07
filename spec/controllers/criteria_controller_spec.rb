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
        @assignment = create(:assignment)
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
        @assignment = create(:assignment)
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
                .to receive(:update).and_return(false)
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
                    flexible_criterion:   { name: 'first'},
                    new_criterion_prompt: 'first',
                    criterion_type:       'FlexibleCriterion',
                    max_mark_prompt:      10
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
                    flexible_criterion:   { name: 'first'},
                    new_criterion_prompt: 'first',
                    criterion_type:       'FlexibleCriterion',
                    max_mark_prompt:      10
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
        @assignment = create(:assignment)
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
  end # Tests using Flexible Criteria only

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
        @assignment = create(:assignment)
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
        @assignment = create(:assignment)
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
                .to receive(:update).and_return(false)
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
                    rubric_criterion:     { name: 'first'},
                    new_criterion_prompt: 'first',
                    criterion_type:       'RubricCriterion',
                    max_mark_prompt:      10
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
                    rubric_criterion:     { name: 'first'},
                    new_criterion_prompt: 'first',
                    criterion_type:       'RubricCriterion',
                    max_mark_prompt:      10
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
        @assignment = create(:assignment)
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
  end # Tests using Rubric Criteria only

  describe 'An authenticated and authorized admin performing yml actions' do
    context 'When a file containing a mixture of entries is uploaded' do
      before :each do
        @admin              = create(:admin)
        @assignment         = create(:assignment)
        @rubric_criterion   = create(:rubric_criterion,
                                     assignment: @assignment,
                                     position: 1,
                                     name: 'Rubric criterion')
        @flexible_criterion = create(:flexible_criterion,
                                     assignment: @assignment,
                                     position: 2,
                                     name: 'Flexible criterion')
        @checkbox_criterion = create(:checkbox_criterion,
                                     assignment: @assignment,
                                     position: 3,
                                     name: 'Checkbox criterion')

        @invalid_file = fixture_file_upload(
            'files/bad_csv.csv', 'text/xls')
        allow(@invalid_file).to receive(:read).and_return(
            File.read(fixture_file_upload(
                          'files/bad_csv.csv', 'text/csv')))

        @empty_file = fixture_file_upload(
          'files/empty_file', 'text/yaml')
        allow(@empty_file).to receive(:read).and_return(
          File.read(fixture_file_upload(
            'files/empty_file', 'text/yaml')))

        @uploaded_file = fixture_file_upload(
          'files/criteria/upload_yml_mixed.yaml', 'text/yaml')
        allow(@uploaded_file).to receive(:read).and_return(
          File.read(fixture_file_upload(
          'files/criteria/upload_yml_mixed.yaml', 'text/yaml')))

        @download_expected_output = fixture_file_upload(
          'files/criteria/download_yml_output.yaml', 'text/yaml')
        allow(@download_expected_output).to receive(:read).and_return(
          File.read(fixture_file_upload(
          'files/criteria/download_yml_output.yaml', 'text/yaml')))
      end

      it 'raises an error if the file does not have properly formatted entries' do
        post_as @admin,
                :upload_yml,
                assignment_id: @assignment.id,
                yml_upload:    { rubric: @invalid_file }

        expect(flash[:error])
            .to eq([I18n.t('criteria.upload.error.invalid_format') + '  ' +
                    'There is an error in the file you uploaded: (<unknown>): invalid trailing UTF-8 octet at line 1 column 1'])
      end

      it 'raises an error if the file does not include any criteria' do
        post_as @admin,
                :upload_yml,
                assignment_id: @assignment.id,
                yml_upload:    { rubric: @empty_file }

        expect(flash[:error])
          .to eq([I18n.t('criteria.upload.error.invalid_format') +
                  '  ' + I18n.t('criteria.upload.empty_error')])
      end

      it 'deletes all criteria previously created' do
        post_as @admin,
                :upload_yml,
                assignment_id: @assignment.id,
                yml_upload:    { rubric: @uploaded_file }

        expect(@assignment.get_criteria.map(&:id))
          .not_to include(@rubric_criterion.id, @flexible_criterion.id, @checkbox_criterion.id)
      end

      it 'maintains the order between entries and positions for criteria' do
        post_as @admin,
                :upload_yml,
                assignment_id: @assignment.id,
                yml_upload:    { rubric: @uploaded_file }

        expect(@assignment.get_criteria.map{ |cr| [cr.name, cr.position] })
          .to match_array([['cr30', 1], ['cr20', 2], ['cr100', 3], ['cr80', 4], ['cr60', 5]])
      end

      it 'creates all criteria with properly formatted entries' do
        post_as @admin,
                :upload_yml,
                assignment_id: @assignment.id,
                yml_upload:    { rubric: @uploaded_file }

        expect(@assignment.get_criteria.map(&:name))
            .to contain_exactly('cr30', 'cr20', 'cr100', 'cr80', 'cr60')
        expect(flash[:success])
          .to eq([I18n.t('criteria.upload.success', num_loaded: 5)])
      end

      it 'creates rubric criteria with properly formatted entries' do
        post_as @admin,
                :upload_yml,
                assignment_id: @assignment.id,
                yml_upload:    { rubric: @uploaded_file }

        expect(@assignment.get_criteria(:all, :rubric).pluck(:name))
          .to include('cr30')
        @assignment.reload
        cr1 = @assignment.get_criteria(:all, :rubric).find_by(name: 'cr30')
        expect(@assignment.get_criteria(:all, :rubric).size).to eq(1)
        expect(cr1.level_0_name).to eq('What?')
        expect(cr1.level_0_description).to eq('Fail')
        expect(cr1.level_1_name).to eq('Hmm')
        expect(cr1.level_1_description).to eq('Almost fail')
        expect(cr1.level_2_name).to eq('Average')
        expect(cr1.level_2_description).to eq('Not bad')
        expect(cr1.level_3_name).to eq('Good')
        expect(cr1.level_3_description).to eq('Alright')
        expect(cr1.level_4_name).to eq('Excellent')
        expect(cr1.level_4_description).to eq('Impressive')
        expect(cr1.ta_visible).to be false
        expect(cr1.peer_visible).to be true
      end

      it 'creates flexible criteria with properly formatted entries' do
        post_as @admin,
                :upload_yml,
                assignment_id: @assignment.id,
                yml_upload:    { rubric: @uploaded_file }

        expect(@assignment.get_criteria(:all, :flexible).pluck(:name))
          .to include('cr20', 'cr80', 'cr60')
        cr1 = @assignment.get_criteria(:all, :flexible).find_by(name: 'cr80')
        expect(@assignment.get_criteria(:all, :flexible).size).to eq(3)
        expect(cr1.max_mark).to eq(10.0)
        expect(cr1.description).to eq('')
        expect(cr1.ta_visible).to be true
        expect(cr1.peer_visible).to be true
      end

      it 'creates checkbox criteria with properly formatted entries' do
        post_as @admin,
                :upload_yml,
                assignment_id: @assignment.id,
                yml_upload:    { rubric: @uploaded_file }

        expect(@assignment.get_criteria(:all, :checkbox).pluck(:name))
          .to include('cr100')
        cr1 = @assignment.get_criteria(:all, :checkbox).find_by(name: 'cr100')
        expect(@assignment.get_criteria(:all, :checkbox).size).to eq(1)
        expect(cr1.max_mark).to eq(5.0)
        expect(cr1.description).to eq('I am checkbox')
        expect(cr1.ta_visible).to be true
        expect(cr1.peer_visible).to be false
      end

      it 'creates criteria; being case insensitive with the type given' do
        post_as @admin,
                :upload_yml,
                assignment_id: @assignment.id,
                yml_upload:    { rubric: @uploaded_file }

        expect(@assignment.get_criteria(:all, :flexible).pluck(:name))
          .to include('cr20', 'cr80')
      end

      it 'creates criteria that lack a description' do
        post_as @admin,
                :upload_yml,
                assignment_id: @assignment.id,
                yml_upload:    { rubric: @uploaded_file }

        expect(@assignment.get_criteria(:all, :flexible).map(&:name)).to include('cr80')
        expect(FlexibleCriterion.find_by(name: 'cr80').description).to eq('')
      end

      it 'creates criteria with the default visibility options if these are not given in the entries' do
        post_as @admin,
                :upload_yml,
                assignment_id: @assignment.id,
                yml_upload:    { rubric: @uploaded_file }

        expect(@assignment.get_criteria.map(&:name)).to include('cr100', 'cr60')
        expect(CheckboxCriterion.find_by(name: 'cr100').ta_visible).to be true
        expect(CheckboxCriterion.find_by(name: 'cr100').peer_visible).to be false
        expect(FlexibleCriterion.find_by(name: 'cr60').ta_visible).to be true
        expect(FlexibleCriterion.find_by(name: 'cr60').peer_visible).to be false
      end

      it 'does not create criteria with format errors in entries' do
        post_as @admin,
                :upload_yml,
                assignment_id: @assignment.id,
                yml_upload:    { rubric: @uploaded_file }

        expect(@assignment.get_criteria.map(&:name))
          .not_to include('cr40', 'cr50', 'cr70')
        expect(flash[:error])
          .to eq([I18n.t('criteria.upload.error.invalid_format') + ' cr40, cr70, cr50'])
      end

      it 'does not create criteria with an invalid mark' do
        post_as @admin,
                :upload_yml,
                assignment_id: @assignment.id,
                yml_upload:    { rubric: @uploaded_file }

        expect(@assignment.get_criteria.map(&:name))
          .not_to include('cr40', 'cr50')
      end

      it 'does not create criteria that have both visibility options set to false' do
        post_as @admin,
                :upload_yml,
                assignment_id: @assignment.id,
                yml_upload:    { rubric: @uploaded_file }

        expect(@assignment.get_criteria.map(&:name))
          .not_to include('cr70')
      end

      context 'When some criteria have been previously uploaded and and admin performs a download' do
        it 'responds with appropriate status' do
          post_as @admin,
                  :upload_yml,
                  assignment_id: @assignment.id,
                  yml_upload:    { rubric: @uploaded_file }

          get :download_yml,
              assignment_id: @assignment.id

          expect(response.status).to eq(200)
        end

        it 'sends the correct information' do
          post_as @admin,
                  :upload_yml,
                  assignment_id: @assignment.id,
                  yml_upload:    { rubric: @uploaded_file }

          get :download_yml,
              assignment_id: @assignment.id

          expect(response.body).to eq(@download_expected_output.read)
        end
      end
    end
  end
end

