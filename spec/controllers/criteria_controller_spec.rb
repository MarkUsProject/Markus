describe CriteriaController do
  describe 'Using Flexible Criteria' do

    describe 'An unauthenticated and unauthorized user doing a GET' do
      context '#index' do
        it 'should respond with redirect' do
          get :index, params: { assignment_id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#new' do
        it 'should respond with redirect' do
          get :new, params: { assignment_id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#edit' do
        it 'should respond with redirect' do
          get :edit, params: { assignment_id: 1, id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#update' do
        it 'should respond with redirect' do
          put :update, params: { assignment_id: 1, id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#destroy' do
        it 'should respond with redirect' do
          delete :destroy, params: { assignment_id: 1, id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#update_positions' do
        it 'should respond with redirect' do
          get :update_positions, params: { assignment_id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context 'with an assignment' do
        before :each do
          @grouping = FactoryBot.create(:grouping)
          @assignment = @grouping.assignment
        end

        context 'and a submission' do
          before :each do
            @submission = create(:submission, grouping: @grouping)
          end

          context '#edit' do
            it 'should respond with redirect' do
              get :edit, params: { assignment_id: @assignment.id, submission_id: @submission.id, id: 1 }
              is_expected.to respond_with :redirect
            end
          end
        end
      end

      context '#download' do
        it 'should respond with redirect' do
          get :download, params: { assignment_id: 1 }
          is_expected.to respond_with :redirect
        end
      end
    end

    describe 'An unauthenticated and unauthorized user doing a POST' do
      context '#index' do
        it 'should respond with redirect' do
          post :index, params: { assignment_id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#new' do
        it 'should respond with redirect' do
          post :new, params: { assignment_id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#update' do
        it 'should respond with redirect' do
          put :update, params: { assignment_id: 1, id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#edit' do
        it 'should respond with redirect' do
          post :edit, params: { assignment_id: 1, id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#destroy' do
        it 'should respond with redirect' do
          delete :destroy, params: { assignment_id: 1, id: 1 }
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
          get_as @admin, :index, params: { assignment_id: @assignment.id }
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
                 params: { assignment_id: @assignment.id, criterion_type: 'FlexibleCriterion'},
                 format: :js
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
                 params: { assignment_id: 1, id: @criterion.id, criterion_type: @criterion.class.to_s },
                 format: :js
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
                .to receive(:errors).and_return(ActiveModel::Errors.new(@criterion))

            get_as @admin,
                   :update,
                   params: { assignment_id: 1, id: @criterion.id, flexible_criterion: { name: 'one', max_mark: 10 },
                             criterion_type: 'FlexibleCriterion' },
                   format: :js
          end

          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
          end

          it 'should respond with unprocessable entity' do
            is_expected.to respond_with(:unprocessable_entity)
          end
        end

        context 'without errors' do
          before(:each) do
            get_as @admin,
                   :update,
                   params: { assignment_id: 1, id: @criterion.id, flexible_criterion: { name: 'one', max_mark: 10 },
                             criterion_type: 'FlexibleCriterion' },
                   format: :js
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
          post_as @admin, :index, params: { assignment_id: @assignment.id }
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
            expect_any_instance_of(FlexibleCriterion)
                .to receive(:update).and_return(false)
            expect_any_instance_of(FlexibleCriterion)
                .to receive(:errors).and_return(ActiveModel::Errors.new(self))
            post_as @admin,
                    :create,
                    params: { assignment_id: @assignment.id, flexible_criterion: { name: 'first', max_mark: 10 },
                              new_criterion_prompt: 'first', criterion_type: 'FlexibleCriterion' },
                    format: :js
          end
          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
            expect(assigns(:assignment)).to be_truthy
          end

          it 'should respond with unprocessable entity' do
            is_expected.to respond_with(:unprocessable_entity)
          end
        end

        context 'without error on an assignment as the first criterion' do
          before(:each) do
            post_as @admin,
                    :create,
                    params: { assignment_id: @assignment.id, flexible_criterion: { name: 'first' },
                              new_criterion_prompt: 'first', criterion_type: 'FlexibleCriterion', max_mark_prompt: 10 },
                    format: :js
          end
          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
            expect(assigns(:assignment)).to be_truthy
          end
          it 'should render the create template' do
            is_expected.to render_template(:'criteria/create')
          end

          it 'should respond with success' do
            is_expected.to respond_with(:success)
          end
        end

        context 'without error on an assignment that already has criteria' do
          before(:each) do
            post_as @admin,
                    :create,
                    params: { assignment_id: @assignment.id, flexible_criterion: { name: 'first' },
                              new_criterion_prompt: 'first', criterion_type: 'FlexibleCriterion', max_mark_prompt: 10 },
                    format: :js
          end
          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
            expect(assigns(:assignment)).to be_truthy
          end
          it 'should render the create template' do
            is_expected.to render_template(:'criteria/create')
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
                  params: { assignment_id: 1, id: @criterion.id, criterion_type: @criterion.class.to_s },
                  format: :js
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
                params: { criterion: ["#{@criterion2.class} #{@criterion2.id}", "#{@criterion.class} #{@criterion.id}"],
                          assignment_id: @assignment.id },
                format: :js
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
                  params: { assignment_id: 1, id: @criterion.id, criterion_type: @criterion.class.to_s },
                  format: :js
        expect(assigns(:criterion)).to be_truthy
        i18t_strings = [I18n.t('flash.criteria.destroy.success')].map { |f| extract_text f }
        expect(i18t_strings).to eql(flash[:success].map { |f| extract_text f })
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
          get :index, params: { assignment_id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#new' do
        it 'should respond with redirect' do
          get :new, params: { assignment_id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#edit' do
        it 'should respond with redirect' do
          get :edit, params: { assignment_id: 1, id: 1 }
          is_expected.to respond_with :redirect
        end

        context 'with an assignment' do
          before :each do
            @grouping = FactoryBot.create(:grouping)
            @assignment = @grouping.assignment
          end

          context 'and a submission' do
            before :each do
              @submission = create(:submission, grouping: @grouping)
            end

            context '#edit' do
              it 'should respond with redirect' do
                get :edit, params: { assignment_id: @assignment.id, submission_id: @submission.id, id: 1 }
                is_expected.to respond_with :redirect
              end
            end
          end
        end
      end

      context '#destroy' do
        it 'should respond with redirect' do
          delete :destroy, params: { assignment_id: 1, id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#update' do
        it 'should respond with redirect' do
          put :update, params: { assignment_id: 1, id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#update_positions' do
        it 'should respond with redirect' do
          get :update_positions, params: { assignment_id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#download' do
        it 'should respond with redirect' do
          get :download, params: { assignment_id: 1 }
          is_expected.to respond_with :redirect
        end
      end
    end

    describe 'An unauthenticated and unauthorized user doing a POST' do
      context '#index' do
        it 'should respond with redirect' do
          post :index, params: { assignment_id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#new' do
        it 'should respond with redirect' do
          post :new, params: { assignment_id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#edit' do
        it 'should respond with redirect' do
          post :edit, params: { assignment_id: 1, id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#update' do
        it 'should respond with redirect' do
          put :update, params: { assignment_id: 1, id: 1 }
          is_expected.to respond_with :redirect
        end
      end

      context '#destroy' do
        it 'should respond with redirect' do
          delete :destroy, params: { assignment_id: 1, id: 1 }
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
          get_as @admin, :index, params: { assignment_id: @assignment.id }
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
                 params: { assignment_id:  @assignment.id, criterion_type: 'RubricCriterion' },
                 format: :js
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
                 params: { assignment_id: 1, id: @criterion.id, criterion_type: @criterion.class.to_s },
                 format: :js
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
                .to receive(:errors).and_return(ActiveModel::Errors.new(@criterion))

            get_as @admin,
                   :update,
                   params: { assignment_id: 1, id: @criterion.id, rubric_criterion: { name: 'one', max_mark: 10 },
                             criterion_type: 'RubricCriterion' },
                   format: :js
          end

          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
          end

          it 'should respond with unprocessable entity' do
            is_expected.to respond_with(:unprocessable_entity)
          end
        end

        context 'without errors' do
          before(:each) do
            get_as @admin,
                   :update,
                   params: { assignment_id: 1, id: @criterion.id, rubric_criterion: { name: 'one', max_mark: 10 },
                             criterion_type: 'RubricCriterion' },
                   format: :js
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
          post_as @admin, :index, params: { assignment_id: @assignment.id }
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
            expect_any_instance_of(RubricCriterion)
                .to receive(:update).and_return(false)
            expect_any_instance_of(RubricCriterion)
                .to receive(:errors).and_return(ActiveModel::Errors.new(self))
            post_as @admin,
                    :create,
                    params: { assignment_id: @assignment.id, rubric_criterion: { name: 'first', max_mark: 10 },
                              new_criterion_prompt: 'first', criterion_type: 'RubricCriterion' },
                    format:  :js
          end
          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
            expect(assigns(:assignment)).to be_truthy
          end

          it 'should respond with unprocessable entity' do
            is_expected.to respond_with(:unprocessable_entity)
          end
        end

        context 'without error on an assignment as the first criterion' do
          before(:each) do
            post_as @admin,
                    :create,
                    params: { assignment_id: @assignment.id, rubric_criterion: { name: 'first' },
                              new_criterion_prompt: 'first', criterion_type: 'RubricCriterion', max_mark_prompt: 10 },
                    format: :js
          end
          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
            expect(assigns(:assignment)).to be_truthy
          end
          it 'should render the create template' do
            is_expected.to render_template(:'criteria/create')
          end

          it 'should respond with success' do
            is_expected.to respond_with(:success)
          end
        end

        context 'without error on an assignment that already has criteria' do
          before(:each) do
            post_as @admin,
                    :create,
                    params: { assignment_id: @assignment.id, rubric_criterion: { name: 'first' },
                              new_criterion_prompt: 'first', criterion_type: 'RubricCriterion', max_mark_prompt: 10 },
                    format: :js
          end
          it 'should respond with appropriate content' do
            expect(assigns(:criterion)).to be_truthy
            expect(assigns(:assignment)).to be_truthy
          end
          it 'should render the create template' do
            is_expected.to render_template(:'criteria/create')
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
                  params: { assignment_id: 1, id: @criterion.id, criterion_type: @criterion.class.to_s },
                  format: :js
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
                params: { criterion: ["#{@criterion2.class} #{@criterion2.id}", "#{@criterion.class} #{@criterion.id}"],
                          assignment_id: @assignment.id },
                format: :js
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
        delete_as @admin,
                  :destroy,
                  params: { assignment_id: 1, id: @criterion.id, criterion_type: @criterion.class.to_s },
                  format: :js
        expect(assigns(:criterion)).to be_truthy
        i18t_string = [I18n.t('flash.criteria.destroy.success')].map { |f| extract_text f }
        expect(i18t_string).to eql(flash[:success].map { |f| extract_text f })
        is_expected.to respond_with(:success)

        expect { RubricCriterion.find(@criterion.id) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end # Tests using Rubric Criteria only

  describe 'An authenticated and authorized admin performing yml actions' do
    before :all do
      @empty_file = fixture_file_upload('files/empty_file', 'text/yaml')
      @test_download_file = fixture_file_upload('files/criteria/criteria_upload_download.yaml', 'text/yaml')
      @download_expected_output = fixture_file_upload('files/criteria/download_yml_output.yaml', 'text/yaml')
      @round_max_mark_file = fixture_file_upload('spec/fixtures/files/criteria/round_max_mark.yaml', 'text/yaml')
      @partially_valid_file = fixture_file_upload('spec/fixtures/files/criteria/partially_valid_file.yaml', 'text/yaml')
    end

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

        @uploaded_file = fixture_file_upload('files/criteria/upload_yml_mixed.yaml', 'text/yaml')
      end

      it 'raises an error if the file does not include any criteria' do
        post_as @admin, :upload, params: { assignment_id: @assignment.id, upload_file: @empty_file }

        expect(flash[:error].map { |f| extract_text f })
          .to eq([I18n.t('upload_errors.blank')].map { |f| extract_text f })
      end

      it 'deletes all criteria previously created' do
        post_as @admin, :upload, params: { assignment_id: @assignment.id, upload_file: @uploaded_file }

        expect(@assignment.rubric_criteria.find_by(name: @rubric_criterion.name)).to be_nil
        expect(@assignment.flexible_criteria.find_by(name: @flexible_criterion.name)).to be_nil
        expect(@assignment.checkbox_criteria.find_by(name: @checkbox_criterion.name)).to be_nil
      end

      it 'maintains the order between entries and positions for criteria' do
        post_as @admin, :upload, params: { assignment_id: @assignment.id, upload_file: @uploaded_file }

        expect(@assignment.get_criteria.map{ |cr| [cr.name, cr.position] })
          .to match_array([['cr30', 1], ['cr20', 2], ['cr100', 3], ['cr80', 4], ['cr60', 5], ['cr90', 6]])
      end

      it 'creates all criteria with properly formatted entries' do
        post_as @admin, :upload, params: { assignment_id: @assignment.id, upload_file: @uploaded_file }

        expect(@assignment.get_criteria.map(&:name)).to contain_exactly('cr30',
                                                                        'cr20',
                                                                        'cr100',
                                                                        'cr80',
                                                                        'cr60',
                                                                        'cr90')
        expect(flash[:success].map { |f| extract_text f })
          .to eq([I18n.t('upload_success', count: 6)].map { |f| extract_text f })
      end

      it 'creates rubric criteria with properly formatted entries' do
        post_as @admin, :upload, params: { assignment_id: @assignment.id, upload_file: @uploaded_file }

        expect(@assignment.get_criteria(:all, :rubric).pluck(:name)).to contain_exactly('cr30', 'cr90')
        cr1 = @assignment.get_criteria(:all, :rubric).find_by(name: 'cr30')
        expect(cr1.levels.size).to eq(5)
        expect(cr1.max_mark).to eq(5.0)
        expect(cr1.ta_visible).to be false
        expect(cr1.peer_visible).to be true
        # Since there are only 5 levels in this rubric criterion, if each of the following queries return an entity,
        # then this rubric criterion is properly sat up.
        expect(cr1.levels.find_by(number: 0, name: 'What?', description: 'Fail', mark: 0)).not_to be_nil
        expect(cr1.levels.find_by(number: 1, name: 'Hmm', description: 'Almost fail', mark: 1)).not_to be_nil
        expect(cr1.levels.find_by(number: 2, name: 'Average', description: 'Not bad', mark: 2)).not_to be_nil
        expect(cr1.levels.find_by(number: 3, name: 'Good', description: 'Alright', mark: 3)).not_to be_nil
        expect(cr1.levels.find_by(number: 4, name: 'Excellent', description: 'Impressive', mark: 5)).not_to be_nil

        cr2 = @assignment.get_criteria(:all, :rubric).find_by(name: 'cr90')
        expect(cr2.max_mark).to eq(4.6)
        expect(cr2.levels.size).to eq(0)
        expect(cr2.ta_visible).to be true
        expect(cr2.peer_visible).to be false
      end
      it 'creates flexible criteria with properly formatted entries' do
        post_as @admin, :upload, params: { assignment_id: @assignment.id, upload_file: @uploaded_file }

        expect(@assignment.get_criteria(:all, :flexible).pluck(:name)).to contain_exactly('cr20', 'cr80', 'cr60')

        cr80 = @assignment.get_criteria(:all, :flexible).find_by(name: 'cr80')
        expect(cr80.max_mark).to eq(10.0)
        expect(cr80.description).to eq('')
        expect(cr80.ta_visible).to be true
        expect(cr80.peer_visible).to be true

        cr20 = @assignment.get_criteria(:all, :flexible).find_by(name: 'cr20')
        expect(cr20.max_mark).to eq(2.0)
        expect(cr20.description).to eq('I am flexible')
        expect(cr20.ta_visible).to be true
        expect(cr20.peer_visible).to be true

        cr60 = @assignment.get_criteria(:all, :flexible).find_by(name: 'cr60')
        expect(cr60.max_mark).to eq(10.0)
        expect(cr60.description).to eq('')
        expect(cr60.ta_visible).to be true
        expect(cr60.peer_visible).to be false
      end

      it 'creates checkbox criteria with properly formatted entries' do
        post_as @admin, :upload, params: { assignment_id: @assignment.id, upload_file: @uploaded_file }

        expect(@assignment.get_criteria(:all, :checkbox).pluck(:name)).to contain_exactly('cr100')
        cr1 = @assignment.get_criteria(:all, :checkbox).find_by(name: 'cr100')
        expect(cr1.max_mark).to eq(5.0)
        expect(cr1.description).to eq('I am checkbox')
        expect(cr1.ta_visible).to be true
        expect(cr1.peer_visible).to be false
      end

      it 'creates criteria being case insensitive with the type given' do
        post_as @admin, :upload, params: { assignment_id: @assignment.id, upload_file: @uploaded_file }

        expect(@assignment.get_criteria(:all, :flexible).pluck(:name)).to contain_exactly('cr20', 'cr80', 'cr60')
      end

      it 'creates criteria that lack a description' do
        post_as @admin, :upload, params: { assignment_id: @assignment.id, upload_file: @uploaded_file }

        expect(@assignment.get_criteria(:all, :flexible).map(&:name)).to include('cr80')
        expect(@assignment.get_criteria(:all, :flexible).find_by(name: 'cr80').description).to eq('')
      end

      it 'creates criteria with the default visibility options if these are not given in the entries' do
        post_as @admin, :upload, params: { assignment_id: @assignment.id, upload_file: @uploaded_file }
        expect(@assignment.get_criteria.map(&:name)).to include('cr100', 'cr60')
        expect(@assignment.get_criteria(:all, :checkbox).find_by(name: 'cr100').ta_visible).to be true
        expect(@assignment.get_criteria(:all, :checkbox).find_by(name: 'cr100').peer_visible).to be false
        expect(@assignment.get_criteria(:all, :flexible).find_by(name: 'cr60').ta_visible).to be true
        expect(@assignment.get_criteria(:all, :flexible).find_by(name: 'cr60').peer_visible).to be false
      end

      it 'creates criteria with rounded (up to first digit after decimal point) maximum mark' do
        post_as @admin, :upload, params: { assignment_id: @assignment.id,
                                           upload_file: @round_max_mark_file }
        # TODO: Fix this
        pending('should be successfully uploaded and it should not create a rubric criterion with default setting')
        expect(@assignment.get_criteria(:all, :rubric).first.name).to eq('cr90')

        expect(@assignment.get_criteria(:all, :rubric).first.max_mark).to eq(4.6)
      end
      it 'does not create criteria with format errors in entries' do
        post_as @admin, :upload, params: { assignment_id: @assignment.id, upload_file: @uploaded_file }

        expect(@assignment.get_criteria.map(&:name))
          .not_to include('cr40', 'cr50', 'cr70')
        expect(flash[:error].map { |f| extract_text f })
          .to eq([I18n.t('criteria.errors.invalid_format') + ' cr40, cr70, cr50'].map { |f| extract_text f })
      end

      it 'does not create criteria with an invalid mark' do
        post_as @admin, :upload, params: { assignment_id: @assignment.id, upload_file: @uploaded_file }

        expect(@assignment.get_criteria.map(&:name)).not_to include('cr40', 'cr50')
      end

      it 'does not create criteria that have both visibility options set to false' do
        post_as @admin, :upload, params: { assignment_id: @assignment.id, upload_file: @uploaded_file }

        expect(@assignment.get_criteria.map(&:name)).not_to include('cr70')
      end

      it 'does not create criteria that have unmatched keys / more keys than required' do
        post_as @admin, :upload, params: { assignment_id: @assignment.id,
                                           upload_file: @partially_valid_file }
        criteria = @assignment.get_criteria(:all, :rubric).first
        expect(criteria.name).to eq('Quality of Writing')
        expect(criteria.levels.size).to eql(4)
        (0..3).each do |i|
          expect(criteria.levels[i].valid? == true)
        end
        expect(criteria.levels[0].name).to eq('Beginner')
        expect(criteria.levels[0].description).to eq('The essay is very poorly organized'\
                                                       ' structure and gives no new information.')
        expect(criteria.levels[0].mark).to eq(10.0)

        expect(criteria.levels[1].name).to eq('Capable')
        expect(criteria.levels[1].description).to eq('The essay is poorly organized but gives new information.')
        expect(criteria.levels[1].mark).to eq(14.0)

        expect(criteria.levels[2].name).to eq('Accomplished')
        expect(criteria.levels[2].description).to eq('The essay is well-structure and conveys new information clearly.')
        expect(criteria.levels[2].mark).to eq(18.0)

        expect(criteria.levels[3].name).to eq('Level 3')
        expect(criteria.levels[3].description).to eq('Level 3 description in one line.')
        expect(criteria.levels[3].mark).to eq(22.0)

        expect(criteria.levels.find_by(number: 4)).to be_nil
        expect(criteria.levels.find_by(number: 5)).to be_nil

        pending('We should report there is an invalid key in the file')
        expect(flash[:error]).not_to be_nil
      end

      context 'When some criteria have been previously uploaded and and admin performs a download' do
        it 'responds with appropriate status' do
          post_as @admin, :upload, params: { assignment_id: @assignment.id, upload_file: @uploaded_file }

          get :download, params: { assignment_id: @assignment.id }

          expect(response.status).to eq(200)
        end

        it 'sends the correct information' do
          post_as @admin, :upload, params: { assignment_id: @assignment.id,
                                             upload_file: @test_download_file }

          get :download, params: { assignment_id: @assignment.id }

          expect(response.body.lines.map(&:strip)).to eq(@download_expected_output.read.lines.map(&:strip))
        end
      end
    end
  end

  let(:assignment) { FactoryBot.create(:assignment) }
  context '#upload', pending: true do # Until criteria tables merged together, can't use Criterion.count
    include_examples 'a controller supporting upload' do
      let(:params) { { assignment_id: assignment.id } }
    end
  end
end
