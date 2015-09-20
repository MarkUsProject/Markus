require 'spec_helper'

describe FlexibleCriteriaController do
  FLEXIBLE_CRITERIA_CSV_STRING = "criterion1,1.0,\"description1, for criterion 1\"\ncriterion2,1.0,\"description2, \"\"with quotes\"\"\"\ncriterion3,1.6,description3!\n"

  describe 'An unauthenticated and unauthorized user doing a GET' do
    context '#index' do
      it 'should respond with redirect' do
        get :index, assignment_id: 1
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

    context '#new' do
      it 'should respond with redirect' do
        get :new, assignment_id: 1
        is_expected.to respond_with :redirect
      end
    end

    context '#destroy' do
      it 'should respond with redirect' do
        delete :destroy, assignment_id: 1, id: 1
        is_expected.to respond_with :redirect
      end
    end

    context '#download' do
      it 'should respond with redirect' do
        get :download, assignment_id: 1
        is_expected.to respond_with :redirect
      end
    end

    context '#upload' do
      it 'should respond with redirect' do
        get :upload, assignment_id: 1
        is_expected.to respond_with :redirect
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
    context '#index' do
      it 'should respond with redirect' do
        post :index, assignment_id: 1
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

    context '#new' do
      it 'should respond with redirect' do
        post :new, assignment_id: 1
        is_expected.to respond_with :redirect
      end
    end

    context '#destroy' do
      it 'should respond with redirect' do
        delete :destroy, assignment_id: 1, id: 1
        is_expected.to respond_with :redirect
      end
    end

    context '#download' do
      it 'should respond with redirect' do
        post :download, assignment_id: 1
        is_expected.to respond_with :redirect
      end
    end

    context '#upload' do
      it 'should respond with redirect' do
        post :upload, assignment_id: 1
        is_expected.to respond_with :redirect
      end
    end

    context '#update_positions' do
      it 'should respond with redirect' do
        post :update_positions, assignment_id: 1
        is_expected.to respond_with :redirect
      end
    end
  end

  describe 'An authenticated and authorized admin doing a GET' do
    before(:all) do
      @admin = create(:admin)
      @assignment = create(:assignment)
      @criterion = create(:flexible_criterion,
                          assignment: @assignment,
                          position: 1,
                          flexible_criterion_name: 'criterion1',
                          description: 'description1, for criterion 1')
      @criterion2 = create(:flexible_criterion,
                           assignment: @assignment,
                           position: 2,
                           flexible_criterion_name: 'criterion2',
                           description: 'description2, "with quotes"')
      @criterion3 = create(:flexible_criterion,
                           assignment: @assignment,
                           position: 3,
                           flexible_criterion_name: 'criterion3',
                           description: 'description3!',
                           max: 1.6)
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

    context '#edit' do
      before(:each) do
        get_as @admin, :edit,
               format: :js,
               assignment_id: 1,
               id: @criterion.id
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
      context 'with save errors' do
        before(:each) do
          expect_any_instance_of(FlexibleCriterion)
            .to receive(:save).and_return(false)
          expect_any_instance_of(FlexibleCriterion)
            .to receive(:errors).and_return('')

          get_as @admin, :update,
                 format: :js,
                 assignment_id: 1,
                 id: @criterion.id,
                 flexible_criterion: { flexible_criterion_name: 'one', max: 10 }
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

      context 'without save errors' do
        before(:each) do
          get_as @admin,
                 :update,
                 format: :js,
                 assignment_id: 1,
                 id: @criterion.id,
                 flexible_criterion: { flexible_criterion_name: 'one', max: 10 }
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

    context '#new' do
      before(:each) do
        get_as @admin, :new,
               format: :js,
               assignment_id: @assignment.id
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

    context '#download' do
      before(:each) do
        get_as @admin, :download, assignment_id: @assignment.id
      end

      it 'should respond with appropriate content' do
        expect(response.header['Content-Type']).to eql('text/csv')
        expect(@response.body).to eql(FLEXIBLE_CRITERIA_CSV_STRING)
        expect(assigns(:assignment)).to be_truthy
      end

      it 'should respond with success' do
        is_expected.to respond_with(:success)
      end
    end

    context '#upload' do
      before(:each) do
        get_as @admin, :upload,
               assignment_id: @assignment.id,
               upload: { flexible: '' }
      end

      it 'should respond with appropriate content' do
        expect(assigns(:assignment)).to be_truthy
      end

      it 'should respond with redirect' do
        is_expected.to respond_with(:redirect)
      end

      it 'should route properly' do
        assert_recognizes({ controller: 'flexible_criteria',
                            assignment_id: '1',
                            action: 'upload' },
                          { path: 'assignments/1/flexible_criteria/upload',
                            method: :post })
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
                          flexible_criterion_name: 'criterion1',
                          description: 'description1, for criterion 1')
      @criterion2 = create(:flexible_criterion,
                           assignment: @assignment,
                           position: 2,
                           flexible_criterion_name: 'criterion2',
                           description: 'description2, "with quotes"')
      @criterion3 = create(:flexible_criterion,
                           assignment: @assignment,
                           position: 3,
                           flexible_criterion_name: 'criterion3',
                           description: 'description3!',
                           max: 1.6)
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

    context '#edit' do
      before(:each) do
        post_as @admin, :edit,
                format: :js,
                assignment_id: 1,
                id: @criterion.id
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

    context '#create' do
      context 'with save error' do
        before(:each) do
          @errors = ActiveModel::Errors.new(self)
          @errors['message'] = 'error message'
          expect_any_instance_of(FlexibleCriterion)
            .to receive(:save).and_return(false)
          expect_any_instance_of(FlexibleCriterion)
            .to receive(:errors).and_return(@errors)
          post_as @admin, :create,
                  format: :js,
                  assignment_id: @assignment.id,
                  flexible_criterion: { flexible_criterion_name: 'first',
                                        max: 10 }
        end
        it 'should respond with appropriate content' do
          expect(assigns(:criterion)).to be_truthy
          expect(assigns(:errors)).to be_truthy
          expect(assigns(:assignment)).to be_truthy
        end

        it 'should render the add_criterion_error template' do
          is_expected
            .to render_template(:'flexible_criteria/add_criterion_error')
        end

        it 'should respond with success' do
          is_expected.to respond_with(:success)
        end
      end

      context 'without error on an assignment as the first criterion' do
        before(:each) do
          post_as @admin, :create,
                  format: :js,
                  assignment_id: @assignment.id,
                  flexible_criterion: { flexible_criterion_name: 'first',
                                        max: 10 }
        end
        it 'should respond with appropriate content' do
          expect(assigns(:criterion)).to be_truthy
          expect(assigns(:assignment)).to be_truthy
        end
        it 'should render the create_and_edit template' do
          is_expected.to render_template(:'flexible_criteria/create_and_edit')
        end

        it 'should respond with success' do
          is_expected.to respond_with(:success)
        end
      end

      context 'without error on an assignment that already has criteria' do
        before(:each) do
          post_as @admin, :create,
                  format: :js,
                  assignment_id: @assignment.id,
                  flexible_criterion: { flexible_criterion_name: 'first',
                                        max: 10 }
        end
        it 'should respond with appropriate content' do
          expect(assigns(:criterion)).to be_truthy
          expect(assigns(:assignment)).to be_truthy
        end
        it 'should render the create_and_edit template' do
          is_expected.to render_template(:'flexible_criteria/create_and_edit')
        end

        it 'should respond with success' do
          is_expected.to respond_with(:success)
        end
      end
    end

    context '#download' do
      before(:each) do
        post_as @admin, :download, assignment_id: @assignment.id
      end

      it 'should respond with success' do
        is_expected.to respond_with(:success)
      end

      it 'should respond with appropriate content' do
        expect(response.header['Content-Type']).to eql('text/csv')
        expect(@response.body).to eql(FLEXIBLE_CRITERIA_CSV_STRING)
        expect(assigns(:assignment)).to be_truthy
      end
    end

    context '#upload' do
      context 'with file containing incomplete records' do
        before(:each) do
          tempfile = fixture_file_upload('/files/flexible_incomplete.csv')
          post_as @admin,
                  :upload,
                  assignment_id: @assignment.id,
                  upload: { flexible: tempfile }
        end
        it 'should respond with appropriate content' do
          expect(assigns(:assignment)).to be_truthy
        end

        it 'should set the flash' do
          is_expected.to set_flash
        end

        it 'should respond with redirect' do
          is_expected.to respond_with(:redirect)
        end
      end

      context 'with file containing partial records' do
        before(:each) do
          tempfile = fixture_file_upload('/files/flexible_partial.csv')
          post_as @admin,
                  :upload,
                  assignment_id: @assignment.id,
                  upload: { flexible: tempfile }
        end
        it 'should respond with appropriate content' do
          expect(assigns(:assignment)).to be_truthy
        end
        it 'should set the flash' do
          is_expected.to set_flash
        end

        it 'should respond with redirect' do
          is_expected.to respond_with(:redirect)
        end
      end

      context 'with file containing full records' do
        before(:each) do
          FlexibleCriterion.destroy_all
          tempfile = fixture_file_upload('/files/flexible_upload.csv')
          post_as @admin,
                  :upload,
                  assignment_id: @assignment.id,
                  upload: { flexible: tempfile }
          @assignment.reload
          @flexible_criteria = @assignment.flexible_criteria
        end
        it 'should respond with appropriate content' do
          expect(assigns(:assignment)).to be_truthy
        end
        it 'should set the flash' do
          is_expected.to set_flash
        end

        it 'should respond with redirect' do
          is_expected.to respond_with(:redirect)
        end

        it 'should have successfully uploaded criteria' do
          expect(@assignment.flexible_criteria.size).to eql(2)
        end
        it 'should keep ordering of uploaded criteria' do
          expect(@flexible_criteria[0].flexible_criterion_name)
            .to eql('criterion3')
          expect(@flexible_criteria[1].flexible_criterion_name)
            .to eql('criterion4')

          expect(@flexible_criteria[0].position).to eql(1)
          expect(@flexible_criteria[1].position).to eql(2)
        end
      end

      context 'with a malformed file' do
        before(:each) do
          tempfile = fixture_file_upload('/files/malformed.csv')
          post_as @admin,
                  :upload,
                  assignment_id: @assignment.id,
                  upload: { flexible: tempfile }
        end
        it 'should respond with appropriate content' do
          expect(assigns(:assignment)).to be_truthy
        end

        it 'should set the flash' do
          expect(flash[:error]).to(
            eql(I18n.t('csv.upload.malformed_csv')))
        end

        it 'should respond with redirect' do
          is_expected.to respond_with(:redirect)
        end
      end

      context 'with a non csv file with csv extension' do
        before(:each) do
          tempfile = fixture_file_upload('/files/pdf_with_csv_extension.csv')
          post_as @admin,
                  :upload,
                  assignment_id: @assignment.id,
                  upload: { flexible: tempfile }
        end
        it 'should respond with appropriate content' do
          expect(assigns(:assignment)).to be_truthy
        end

        it 'should set the flash' do
          expect(flash[:error]).to(
            eql(I18n.t('csv.upload.malformed_csv')))
        end

        it 'should respond with redirect' do
          is_expected.to respond_with(:redirect)
        end
      end
    end

    it 'should be able to update_positions' do
      post_as @admin,
              :update_positions,
              format: :js,
              criterion: [@criterion2.id,
                          @criterion.id],
              assignment_id: @assignment.id
      is_expected.to render_template('flexible_criteria/update_positions')
      is_expected.to respond_with(:success)

      c1 = FlexibleCriterion.find(@criterion.id)
      expect(c1.position).to eql(2)
      c2 = FlexibleCriterion.find(@criterion2.id)
      expect(c2.position).to eql(1)
    end
  end # An authenticated and authorized admin doing a POST

  describe 'An authenticated and authorized admin doing a DELETE' do
    before(:each) do
      @admin = create(:admin)
      @assignment = create(:assignment)
      @criterion = create(:flexible_criterion,
                          assignment: @assignment)
    end

    it ' should be able to delete the criterion' do
      delete_as @admin, :destroy,
                format: :js,
                assignment_id: 1,
                id: @criterion.id
      expect(assigns(:criterion)).to be_truthy
      expect(I18n.t('criterion_deleted_success')).to eql(flash[:success])
      is_expected.to respond_with(:success)

      expect { FlexibleCriterion.find(@criterion.id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
