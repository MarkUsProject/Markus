describe AnnotationCategoriesController do
  let(:course) { assignment.course }
  let(:assignment) { create(:assignment) }
  let(:annotation_category) { create(:annotation_category, assignment: assignment) }

  shared_examples 'A grader or instructor accessing the index or find_annotation_text routes' do
    describe '#index' do
      before { @index_annotation_category = create(:annotation_category, assignment: assignment) }

      it 'should respond with 200 if html is requested' do
        get_as role, :index, params: { course_id: course.id, assignment_id: assignment.id }
        expect(response).to have_http_status(:ok)
      end

      it 'should respond with 200 if json is requested' do
        get_as role,
               :index, params: { course_id: course.id, assignment_id: assignment.id }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it 'should return the correct number of annotation categories if json is requested' do
        get_as role,
               :index, params: { course_id: course.id, assignment_id: assignment.id }, format: :json
        expect(response.parsed_body.size).to eq(1)
      end

      it 'should return the correct annotation category data if json is requested' do
        get_as role,
               :index, params: { course_id: course.id, assignment_id: assignment.id }, format: :json
        res = response.parsed_body[0]
        expect(res['annotation_category_name']).to eq @index_annotation_category.annotation_category_name
        expect(res['id']).to eq @index_annotation_category.id
      end

      it_behaves_like 'role is from a different course' do
        subject { get_as new_role, :index, params: { course_id: course.id, assignment_id: assignment.id } }
      end
    end

    context 'When searching for an annotation text' do
      before do
        @annotation_text_one = create(:annotation_text,
                                      annotation_category: annotation_category,
                                      content: 'This is an annotation text.')
      end

      it 'should render an annotation context, where first part of its content matches given string' do
        string = 'This is an'

        get_as role,
               :find_annotation_text,
               params: { course_id: course.id, assignment_id: assignment.id, string: string }, format: :js
        expect(response.parsed_body[0]['content']).to eq(@annotation_text_one.content)
      end

      it_behaves_like 'role is from a different course' do
        subject do
          get_as new_role, :find_annotation_text,
                 params: { course_id: course.id, assignment_id: assignment.id, string: '' }, format: :js
        end
      end
      it 'should render an empty string if string does not match first part of any annotation text' do
        string = 'Hello'

        get_as role,
               :find_annotation_text,
               params: { course_id: course.id, assignment_id: assignment.id, string: string }, format: :js
        expect(response.parsed_body).to eq([])
      end

      it 'should render multiple matches if string matches first part of more than one annotation text' do
        create(:annotation_text, annotation_category: annotation_category, content: 'This is another annotation text.')
        string = 'This is an'

        get_as role,
               :find_annotation_text,
               params: { course_id: course.id, assignment_id: assignment.id, string: string }, format: :js
        expect(response.parsed_body.size).to eq(2)
      end
    end
  end

  shared_examples 'An authorized user managing annotation categories' do
    it_behaves_like 'A grader or instructor accessing the index or find_annotation_text routes'
    describe '#show' do
      it 'should respond with 200' do
        get_as role, :show, params: { course_id: course.id, assignment_id: assignment.id, id: annotation_category.id }
        expect(response).to have_http_status(:ok)
      end

      it_behaves_like 'role is from a different course' do
        subject do
          get_as new_role, :show,
                 params: { course_id: course.id, assignment_id: assignment.id, id: annotation_category.id }
        end
      end
    end

    describe '#new' do
      it 'should respond with 200' do
        get_as role, :new, params: { course_id: course.id, assignment_id: assignment.id }
        expect(response).to have_http_status(:ok)
      end

      it_behaves_like 'role is from a different course' do
        subject do
          get_as new_role, :new, params: { course_id: course.id, assignment_id: assignment.id }
        end
      end
    end

    describe '#new_annotation_text' do
      it 'should respond with 200' do
        get_as role, :new_annotation_text,
               params: { course_id: course.id, assignment_id: assignment.id,
                         annotation_category_id: annotation_category.id }
        expect(response).to have_http_status(:ok)
      end

      it_behaves_like 'role is from a different course' do
        subject do
          get_as new_role, :new_annotation_text,
                 params: { course_id: course.id, assignment_id: assignment.id,
                           annotation_category_id: annotation_category.id }
        end
      end
    end

    describe '#create' do
      it_behaves_like 'role is from a different course' do
        subject do
          post_as new_role, :create,
                  params: { assignment_id: assignment.id,
                            course_id: course.id,
                            annotation_category: { annotation_category_name: 'Category 1' },
                            format: :js }
        end
      end
      it 'successfully creates annotation_category with nil flexible_criterion' do
        post_as role, :create,
                params: { assignment_id: assignment.id,
                          course_id: course.id,
                          annotation_category: { annotation_category_name: 'Category 1' },
                          format: :js }
        expect(assignment.annotation_categories.find_by(annotation_category_name: 'Category 1')
                   .flexible_criterion).to be_nil
      end

      it 'successfully creates a new annotation category when given a unique name' do
        post_as role, :create,
                params: { assignment_id: assignment.id,
                          course_id: course.id,
                          annotation_category: { annotation_category_name: 'New Category' },
                          format: :js }

        expect(assignment.annotation_categories.count).to eq 1
        expect(assignment.annotation_categories.first.annotation_category_name).to eq 'New Category'
      end

      it 'fails when the annotation category name is already used' do
        category = create(:annotation_category, assignment: assignment)
        post_as role, :create,
                params: { assignment_id: assignment.id,
                          course_id: course.id,
                          annotation_category: { annotation_category_name: category.annotation_category_name },
                          format: :js }
        expect(assignment.annotation_categories.count).to eq 1
      end
    end

    describe '#update' do
      it_behaves_like 'role is from a different course' do
        subject do
          patch_as new_role, :update,
                   params: { assignment_id: assignment.id,
                             course_id: course.id,
                             id: annotation_category.id,
                             annotation_category: { annotation_category_name: 'Updated category' },
                             format: :js }
        end
      end
      it 'successfully updates an annotation category name' do
        patch_as role, :update,
                 params: { assignment_id: assignment.id,
                           course_id: course.id,
                           id: annotation_category.id,
                           annotation_category: { annotation_category_name: 'Updated category' },
                           format: :js }
        expect(annotation_category.reload.annotation_category_name).to eq 'Updated category'
      end

      it 'fails when the annotation category name is already used' do
        original_name = annotation_category.annotation_category_name
        category2 = create(:annotation_category, assignment: assignment)

        patch_as role, :update,
                 params: { assignment_id: assignment.id,
                           course_id: course.id,
                           id: annotation_category.id,
                           annotation_category: { annotation_category_name: category2.annotation_category_name } }

        expect(annotation_category.reload.annotation_category_name).to eq original_name
      end

      it 'successfully sets the AnnotationCategory\'s associated flexible_criterion' do
        assignment = annotation_category.assignment
        flexible_criterion = create(:flexible_criterion, assignment: assignment)

        patch_as role, :update,
                 params: { assignment_id: assignment.id,
                           course_id: course.id,
                           id: annotation_category.id,
                           annotation_category: { flexible_criterion_id: flexible_criterion.id },
                           format: :js }

        expect(annotation_category.reload.flexible_criterion_id).to eq(flexible_criterion.id)
      end

      it 'successfully updates the AnnotationCategory\'s associated flexible_criterion to nil' do
        assignment = create(:assignment_with_deductive_annotations)
        category = assignment.annotation_categories.where.not(flexible_criterion_id: nil).first

        patch_as role, :update,
                 params: { assignment_id: assignment.id,
                           course_id: course.id,
                           id: category.id,
                           annotation_category: { flexible_criterion_id: '' },
                           format: :js }

        expect(category.reload.flexible_criterion_id).to be_nil
      end

      it 'fails to update the AnnotationCategory\'s associated flexible_criterion to an id ' \
         'of a criterion for another assignment' do
        assignment = annotation_category.assignment
        flexible_criterion = create(:flexible_criterion)

        patch_as role, :update,
                 params: { assignment_id: assignment.id,
                           course_id: course.id,
                           id: annotation_category.id,
                           annotation_category: { flexible_criterion_id: flexible_criterion.id },
                           format: :js }
        expect(annotation_category.flexible_criterion_id).to be_nil
      end

      it 'fails to update the AnnotationCategory\'s associated flexible_criterion' \
         'after results have been released' do
        assignment = create(:assignment_with_deductive_annotations)
        category = assignment.annotation_categories.where.not(flexible_criterion_id: nil).first
        flexible_criterion = create(:flexible_criterion, assignment: assignment)
        assignment.groupings.first.current_result.update!(released_to_students: true)
        previous_criterion_id = category.flexible_criterion_id
        patch_as role, :update,
                 params: { assignment_id: assignment.id,
                           course_id: course.id,
                           id: category.id,
                           annotation_category: { flexible_criterion_id: flexible_criterion.id },
                           format: :js }
        expect(category.reload.flexible_criterion_id).to eq(previous_criterion_id)
      end
    end

    describe '#annotation_text_uses' do
      let(:assignment) { create(:assignment_with_criteria_and_results) }
      let(:category) { create(:annotation_category, assignment: assignment) }
      let(:annotation_text) { create(:annotation_text, annotation_category: annotation_category) }

      it_behaves_like 'role is from a different course' do
        subject do
          get_as new_role,
                 :annotation_text_uses,
                 params: { assignment_id: assignment.id,
                           course_id: course.id,
                           annotation_text_id: annotation_text.id },
                 format: :json
        end
      end

      it 'returns the correct data if the annotation_text was used once' do
        create(:text_annotation,
               annotation_text: annotation_text,
               creator: role,
               result: assignment.groupings.first.current_result)
        get_as role,
               :annotation_text_uses,
               params: { assignment_id: assignment.id,
                         course_id: course.id,
                         annotation_text_id: annotation_text.id },
               format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.size).to eq 1
        uses = response.parsed_body.first
        expect(uses['result_id']).to eq assignment.groupings.first.current_result.id
        expect(uses['assignment_id']).to eq assignment.id
        expect(uses['user_name']).to eq role.user_name
        expect(uses['submission_id']).to eq assignment.groupings.first.current_result.submission_id
      end

      it 'returns the correct data if the annotation_text was used more than once' do
        one_grouping = assignment.groupings.first
        another_grouping = assignment.groupings.second
        create(:text_annotation,
               annotation_text: annotation_text,
               creator: role,
               result: one_grouping.current_result)
        create(:text_annotation,
               annotation_text: annotation_text,
               creator: role,
               result: another_grouping.current_result)
        get_as role,
               :annotation_text_uses,
               params: { assignment_id: assignment.id,
                         course_id: course.id,
                         annotation_text_id: annotation_text.id },
               format: :json
        expect(response).to have_http_status(:ok)
        res = response.parsed_body
        expect(res.size).to eq 2
        results = [res.first['result_id'], res.second['result_id']].sort!
        expect(results).to eq [one_grouping.current_result.id, another_grouping.current_result.id].sort!
        expect([res.first['user_name'], res.second['user_name']]).to eq [role.user_name, role.user_name]
        expect([res.first['assignment_id'], res.second['assignment_id']]).to eq [assignment.id, assignment.id]
      end

      it 'returns the correct data if the annotation_text was never used' do
        get_as role,
               :annotation_text_uses,
               params: { assignment_id: assignment.id,
                         course_id: course.id,
                         annotation_text_id: annotation_text.id },
               format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq []
      end
    end

    describe '#update_positions' do
      it 'successfully updates annotation category positions' do
        cat1 = create(:annotation_category, assignment: assignment)
        cat2 = create(:annotation_category, assignment: assignment)
        cat3 = create(:annotation_category, assignment: assignment)

        post_as role, :update_positions,
                params: { assignment_id: assignment.id,
                          course_id: course.id,
                          annotation_category: [cat3.id, cat1.id, cat2.id] }

        expect(cat3.reload.position).to eq 0
        expect(cat1.reload.position).to eq 1
        expect(cat2.reload.position).to eq 2
      end

      it_behaves_like 'role is from a different course' do
        subject do
          post_as new_role, :update_positions,
                  params: { assignment_id: assignment.id,
                            course_id: course.id,
                            annotation_category: [] }
        end
      end
    end

    describe '#destroy' do
      it 'successfully deletes an annotation category' do
        delete_as role,
                  :destroy,
                  format: :js,
                  params: { course_id: course.id, assignment_id: assignment.id, id: annotation_category.id }

        expect(assignment.annotation_categories.count).to eq 0
      end

      it_behaves_like 'role is from a different course' do
        subject do
          delete_as new_role,
                    :destroy,
                    format: :js,
                    params: { course_id: course.id, assignment_id: assignment.id, id: annotation_category.id }
        end
      end
    end

    describe '#create_annotation_text' do
      it_behaves_like 'role is from a different course' do
        subject do
          post_as new_role, :create_annotation_text,
                  params: { assignment_id: annotation_category.assessment_id,
                            course_id: course.id,
                            content: 'New content',
                            annotation_category_id: annotation_category.id,
                            format: :js }
        end
      end
      it 'successfully creates an annotation text associated with an annotation category' do
        post_as role, :create_annotation_text,
                params: { assignment_id: annotation_category.assessment_id,
                          course_id: course.id,
                          content: 'New content',
                          annotation_category_id: annotation_category.id,
                          format: :js }

        expect(annotation_category.annotation_texts.count).to eq 1
        expect(annotation_category.annotation_texts.first.content).to eq 'New content'
      end

      it 'successfully creates an annotation text associated with an annotation category with a deduction' do
        assignment_w_deductions = create(:assignment_with_deductive_annotations)
        category = assignment_w_deductions.annotation_categories.where.not(flexible_criterion_id: nil).first
        category.annotation_texts.destroy_all
        category.reload
        post_as role, :create_annotation_text,
                params: { assignment_id: category.assessment_id,
                          course_id: course.id,
                          content: 'New content',
                          annotation_category_id: category.id,
                          deduction: 0.5,
                          format: :js }
        expect(category.annotation_texts.first.deduction).to eq 0.5
      end

      it 'does not allow creation of an annotation text associated with an annotation category with a deduction ' \
         'with a nil deduction' do
        assignment_w_deductions = create(:assignment_with_deductive_annotations)
        category = assignment_w_deductions.annotation_categories.where.not(flexible_criterion_id: nil).first
        category.annotation_texts.destroy_all
        post_as role, :create_annotation_text,
                params: { assignment_id: category.assessment_id,
                          course_id: course.id,
                          content: 'New content',
                          annotation_category_id: category.id,
                          deduction: nil,
                          format: :js }
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe '#update_annotation_text' do
      let(:assignment) { create(:assignment_with_criteria_and_results) }
      let(:assignment_result) { assignment.groupings.first.current_result }
      let(:uncategorized_text) { create(:annotation_text, annotation_category: nil) }

      it_behaves_like 'role is from a different course' do
        subject do
          text = create(:annotation_text)
          category = text.annotation_category
          put_as new_role, :update_annotation_text,
                 params: { assignment_id: category.assessment_id,
                           course_id: course.id,
                           annotation_text_id: text.id,
                           content: 'updated content',
                           format: :js }
        end
      end

      it 'successfully updates an annotation text\'s (associated with an annotation category) content' do
        text = create(:annotation_text)
        category = text.annotation_category
        put_as role, :update_annotation_text,
               params: { assignment_id: category.assessment_id,
                         course_id: course.id,
                         annotation_text_id: text.id,
                         content: 'updated content',
                         format: :js }

        expect(text.reload.content).to eq 'updated content'
      end

      it 'successfully updates an annotation text\'s (associated with an annotation category) deduction' do
        assignment_w_deductions = create(:assignment_with_deductive_annotations)
        category = assignment_w_deductions.annotation_categories.where.not(flexible_criterion_id: nil).first
        text = category.annotation_texts.first
        put_as role, :update_annotation_text,
               params: { assignment_id: category.assessment_id,
                         course_id: course.id,
                         annotation_text_id: text.id,
                         content: 'more updated content',
                         deduction: 0.1,
                         format: :js }

        expect(text.reload.deduction).to eq 0.1
      end

      it 'correctly responds when updating an annotation text\'s (associated with an annotation category) ' \
         'deduction with nil value when its category belongs to a flexible criterion' do
        assignment_w_deductions = create(:assignment_with_deductive_annotations)
        category = assignment_w_deductions.annotation_categories.where.not(flexible_criterion_id: nil).first
        text = category.annotation_texts.first
        put_as role, :update_annotation_text,
               params: { assignment_id: category.assessment_id,
                         course_id: course.id,
                         annotation_text_id: text.id,
                         content: 'more updated content',
                         deduction: nil,
                         format: :js }

        expect(response).to have_http_status(:bad_request)
        expect(text.reload.deduction).not_to be_nil
      end

      it 'fails to update an annotation text\'s (associated with an annotation category) ' \
         'content when it is a deductive annotation that has been applied to released results' do
        assignment_w_deductions = create(:assignment_with_deductive_annotations)
        category = assignment_w_deductions.annotation_categories.where.not(flexible_criterion_id: nil).first
        text = category.annotation_texts.first
        prev_content = text.content
        assignment_w_deductions.groupings.first.current_result.update!(released_to_students: true)
        put_as role, :update_annotation_text,
               params: { assignment_id: category.assessment_id,
                         course_id: course.id,
                         annotation_text_id: text.id,
                         annotation_text: { content: 'more updated content', deduction: nil },
                         format: :js }

        expect(response).to have_http_status(:bad_request)
        expect(text.reload.content).to eq(prev_content)
      end

      it 'successfully updates an annotation text\'s (not associated with an annotation category) content' do
        create(:text_annotation, annotation_text: uncategorized_text, result: assignment_result)
        put_as role, :update_annotation_text,
               params: { assignment_id: assignment.id,
                         course_id: course.id,
                         annotation_text_id: uncategorized_text.id,
                         content: 'updated_content',
                         format: :js }

        expect(uncategorized_text.reload.content).to eq 'updated_content'
      end
    end

    describe '#uncategorized_annotations' do
      let(:assignment) { create(:assignment_with_criteria_and_results) }
      let(:assignment_result) { assignment.groupings.first.current_result }
      let(:text) { create(:annotation_text, annotation_category: nil) }
      let(:different_text) { create(:annotation_text, annotation_category: nil) }
      let(:last_editor) { create(:instructor) }
      let(:text2) { create(:annotation_text, annotation_category: nil, last_editor: last_editor) }

      it 'finds no instance of uncategorized annotations when there are no annotation texts' do
        get_as role, :uncategorized_annotations, params: { course_id: course.id, assignment_id: assignment.id }
        expect(assigns['texts']).to eq []
      end

      it_behaves_like 'role is from a different course' do
        subject do
          get_as new_role, :uncategorized_annotations, params: { course_id: course.id, assignment_id: assignment.id }
        end
      end
      it 'finds no instance of uncategorized annotations when only categorized annotation texts exists' do
        category = create(:annotation_category, assignment: assignment)
        categorized_text = create(:annotation_text, annotation_category: category)
        create(:text_annotation, annotation_text: categorized_text, result: assignment_result)
        get_as role, :uncategorized_annotations, params: { course_id: course.id, assignment_id: assignment.id }
        expect(assigns['texts']).to eq []
      end

      it 'does not find uncategorized annotations from other assignments' do
        other_assignment = create(:assignment_with_criteria_and_results)
        create(:text_annotation, annotation_text: text, result: other_assignment.groupings.first.current_result)
        get_as role, :uncategorized_annotations, params: { course_id: course.id, assignment_id: assignment.id }
        expect(assigns['texts']).to eq []
      end

      it 'finds one uncategorized annotation if only one exists' do
        create(:text_annotation, annotation_text: text, result: assignment_result)
        get_as role, :uncategorized_annotations, params: { course_id: course.id, assignment_id: assignment.id }
        expect(assigns['texts'].first['id']).to eq text.id
      end

      it 'finds multiple uncategorized annotations if many exist' do
        create(:text_annotation, annotation_text: text, result: assignment_result)
        create(:text_annotation, annotation_text: different_text, result: assignment_result)
        get_as role, :uncategorized_annotations, params: { course_id: course.id, assignment_id: assignment.id }
        expect(assigns['texts'].size).to eq 2
        expect([assigns['texts'].first['id'], assigns['texts'].second['id']].sort!).to eq [text.id,
                                                                                           different_text.id].sort!
      end

      it 'finds uncategorized annotations if they exist across different results' do
        create(:text_annotation, annotation_text: text, result: assignment_result)
        other_grouping = assignment.groupings.where.not(id: assignment_result.grouping.id).first
        create(:text_annotation, annotation_text: different_text, result: other_grouping.current_result)
        get_as role, :uncategorized_annotations, params: { course_id: course.id, assignment_id: assignment.id }
        expect(assigns['texts'].size).to eq 2
        expect([assigns['texts'].first['id'], assigns['texts'].second['id']].sort!).to eq [text.id,
                                                                                           different_text.id].sort!
      end

      it 'is not empty when responding to json format and uncategorized annotations exist' do
        create(:text_annotation, annotation_text: text, result: assignment_result)
        get_as role, :uncategorized_annotations, format: 'json',
                                                 params: { course_id: course.id, assignment_id: assignment.id }
        expect(response.parsed_body).not_to be_empty
      end

      it 'has correct keys when responding to json format and uncategorized annotations exist' do
        create(:text_annotation, annotation_text: text, result: assignment_result)
        other_grouping = assignment.groupings.where.not(id: assignment_result.grouping.id).first
        create(:text_annotation, annotation_text: different_text, result: other_grouping.current_result)
        expected_keys = %w[group_name creator last_editor content assignment_id result_id submission_id id]
        get_as role,
               :uncategorized_annotations,
               format: 'json',
               params: { course_id: course.id, assignment_id: assignment.id }
        data = response.parsed_body
        expect(data.first.keys).to match_array expected_keys
        expect(data.second.keys).to match_array expected_keys
      end

      it 'has correct data when responding to json format and uncategorized annotation exists' do
        create(:text_annotation, annotation_text: text2, result: assignment_result)
        get_as role,
               :uncategorized_annotations,
               format: 'json',
               params: { course_id: course.id, assignment_id: assignment.id }
        data = response.parsed_body
        expect(data.first['group_name']).to eq(assignment.groupings.first.group.group_name)
        expect(data.first['creator']).to eq(text2.creator.user_name)
        expect(data.first['last_editor']).to eq(last_editor.user_name)
        expect(data.first['content']).to eq(text2.content)
        expect(data.first['assignment_id']).to eq(assignment.id)
        expect(data.first['result_id']).to eq(assignment_result.id)
        expect(data.first['submission_id']).to eq(assignment.groupings.first.current_result.submission_id)
        expect(data.first['id']).to eq(text2.id)
      end

      describe 'Download One Time Annotations' do
        let(:course2) { create(:course) }
        let(:assignment2) { create(:assignment, course: course2) }

        it 'should respond with 200' do
          get_as role, :uncategorized_annotations, params: { course_id: course.id, assignment_id: assignment.id },
                                                   format: 'csv'
          expect(response).to have_http_status(:ok)
        end

        it 'should respond with 404' do
          get_as role, :uncategorized_annotations,
                 params: { course_id: course2.id, assignment_id: assignment2.id, id: annotation_category.id },
                 format: 'csv'
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe '#destroy_annotation_text' do
      let(:assignment) { create(:assignment_with_criteria_and_results) }
      let(:assignment_result) { assignment.groupings.first.current_result }
      let(:uncategorized_text) { create(:annotation_text, annotation_category: nil) }

      it 'successfully destroys an annotation text associated with an annotation category' do
        text = create(:annotation_text)
        category = text.annotation_category
        delete_as role, :destroy_annotation_text,
                  params: { assignment_id: category.assessment_id,
                            course_id: course.id,
                            annotation_text_id: text.id,
                            format: :js }

        expect(category.annotation_texts.count).to eq 0
      end

      it_behaves_like 'role is from a different course' do
        subject do
          text = create(:annotation_text)
          category = text.annotation_category
          delete_as new_role, :destroy_annotation_text,
                    params: { assignment_id: category.assessment_id,
                              course_id: course.id,
                              annotation_text_id: text.id,
                              format: :js }
        end
      end
      it 'successfully destroys an annotation text not associated with an annotation category' do
        create(:text_annotation, annotation_text: uncategorized_text, result: assignment_result)
        get_as role, :uncategorized_annotations, params: { course_id: course.id, assignment_id: assignment.id }
        expect(assigns['texts'].first['id']).to eq uncategorized_text.id
        delete_as role, :destroy_annotation_text,
                  params: { assignment_id: assignment.id,
                            course_id: course.id,
                            annotation_text_id: uncategorized_text.id,
                            format: :js }

        get_as role, :uncategorized_annotations, params: { course_id: course.id, assignment_id: assignment.id }
        expect(assigns['texts']).to eq []
      end
    end

    describe '#upload' do
      it_behaves_like 'a controller supporting upload' do
        let(:params) { { course_id: course.id, assignment_id: assignment.id } }
      end
      it_behaves_like 'role is from a different course' do
        subject do
          post_as new_role, :upload, params: { course_id: course.id, assignment_id: assignment.id, upload_file: '' }
        end
      end
      it 'accepts a valid csv file without deductive annotation info' do
        file_good = fixture_file_upload('annotation_categories/form_good.csv', 'text/csv')
        post_as role, :upload, params: { course_id: course.id, assignment_id: assignment.id, upload_file: file_good }

        expect(response).to have_http_status(:found)
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to have_message(I18n.t('upload_success', count: 2))
        expect(response).to redirect_to(action: 'index', assignment_id: assignment.id)

        expect(AnnotationCategory.all.size).to eq(2)
        # check that the data is being updated, in particular
        # the last element in the file.
        test_category_name = 'test_category'
        test_content = 'c6conley'
        found_cat = false
        AnnotationCategory.find_each do |ac|
          next unless ac['annotation_category_name'] == test_category_name

          found_cat = true
          expect(AnnotationText.find_by(annotation_category: ac)['content']).to eq(test_content)
        end
        expect(found_cat).to be(true)
      end

      it 'accepts a valid csv file with deductive annotation info' do
        file_good = fixture_file_upload('annotation_categories/form_good_with_deductive_info.csv',
                                        'text/csv')
        create(:flexible_criterion, name: 'hephaestus', assignment: assignment)
        post_as role, :upload, params: { course_id: course.id, assignment_id: assignment.id, upload_file: file_good }

        expect(response).to have_http_status :found
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to have_message(I18n.t('upload_success', count: 3))
        expect(response).to redirect_to(action: 'index', assignment_id: assignment.id)

        expect(AnnotationCategory.all.size).to eq 3
        # check that the data is being updated, in particular
        # the last element in the file.
        test_criterion = 'hephaestus'
        test_text = %w[enyo athena]
        ac = AnnotationCategory.find_by(annotation_category_name: 'Artemis')
        expect(AnnotationText.where(annotation_category: ac).pluck(:content).sort!).to eq(test_text.sort!)
        expect(AnnotationText.where(annotation_category: ac).pluck(:deduction)).to eq([1.0, 1.0])
        expect(ac.flexible_criterion.name).to eq(test_criterion)
      end

      it 'does not accept files with invalid columns' do
        @file_invalid_column = fixture_file_upload('annotation_categories/form_invalid_column.csv', 'text/csv')

        post_as role,
                :upload,
                params: { course_id: course.id, assignment_id: assignment.id, upload_file: @file_invalid_column }

        expect(response).to have_http_status(:found)
        # One annotation category was created, and one has an error.
        expect(AnnotationCategory.all.size).to eq(0)
        expect(flash[:error].size).to eq(1)
        expect(response).to redirect_to(action: 'index', assignment_id: assignment.id)
      end

      it 'accepts a valid yml file without deductive annotation info' do
        @valid_yml_file = fixture_file_upload('annotation_categories/valid_yml.yml', 'text/yml')
        post_as role,
                :upload,
                params: { course_id: course.id, assignment_id: assignment.id, upload_file: @valid_yml_file }
        expect(flash[:success].size).to eq(1)
        expect(response).to have_http_status(:found)

        annotation_category_list = AnnotationCategory.order(:annotation_category_name)
        index = 0
        while index < annotation_category_list.size
          curr_cat = annotation_category_list[index]
          expect(curr_cat.annotation_category_name).to eql("Problem #{index + 1}")
          expect(curr_cat.annotation_texts.all[0].content).to eql("Test on question #{index + 1}")
          index += 1
        end
        expect(annotation_category_list.size).to eq(4)
      end

      it 'accepts a valid yml file with deductive annotation info' do
        @valid_yml_file = fixture_file_upload('annotation_categories/valid_yml_with_deductive_info.yaml',
                                              'text/yml')
        create(:flexible_criterion, assignment: assignment, name: 'cafe')
        create(:flexible_criterion, assignment: assignment, name: 'finland')
        create(:flexible_criterion, assignment: assignment, name: 'artist')
        post_as role,
                :upload,
                params: { course_id: course.id, assignment_id: assignment.id, upload_file: @valid_yml_file }

        expect(flash[:success].size).to eq 1
        expect(response).to have_http_status :found

        annotation_category_list = AnnotationCategory.order(:annotation_category_name)
        test_criterion = 'cafe'
        test_text = ['loan']
        ac = AnnotationCategory.find_by(annotation_category_name: 'fleabag')
        expect(AnnotationText.where(annotation_category: ac).pluck(:content)).to eq(test_text)
        expect(AnnotationText.where(annotation_category: ac).pluck(:deduction)).to eq([1.0])
        expect(ac.flexible_criterion.name).to eq(test_criterion)

        category_without_deductions = AnnotationCategory.where(flexible_criterion_id: nil).first
        expect(category_without_deductions.annotation_category_name).to eq 'Belinda'
        expect(category_without_deductions.annotation_texts.first.content).to eq 'award'
        expect(annotation_category_list.size).to eq(4)
      end

      it 'does not accept files with empty annotation category name' do
        @yml_with_invalid_category = fixture_file_upload('annotation_categories/yml_with_invalid_category.yml')

        post_as role,
                :upload,
                params: { course_id: course.id, assignment_id: assignment.id, upload_file: @yml_with_invalid_category }
        expect(response).to have_http_status(:found)
        expect(flash[:error].size).to eq(1)
        expect(AnnotationCategory.all.size).to eq(0)
        expect(response).to redirect_to action: 'index', assignment_id: assignment.id
      end
    end

    context 'CSV_One_Time_Downloads' do
      let(:assignment) { create(:assignment_with_criteria_and_results) }
      let(:assignment_result) { assignment.groupings.first.current_result }
      let(:last_editor) { create(:instructor) }
      let(:text) { create(:annotation_text, annotation_category: nil, last_editor: last_editor) }
      let(:different_text) { create(:annotation_text, annotation_category: nil) }

      let(:csv_options) do
        { filename: "#{assignment.short_identifier}_one_time_annotations.csv",
          disposition: 'attachment',
          type: 'text/csv' }
      end

      it_behaves_like 'role is from a different course' do
        subject do
          get_as new_role,
                 :uncategorized_annotations,
                 params: { course_id: course.id, assignment_id: assignment.id },
                 format: 'csv'
        end
      end
      it 'expects a call to send_data with editor' do
        text_annotation = create(:text_annotation, annotation_text: text, result: assignment_result)
        csv_data = "#{assignment.groupings.first.group.group_name}," \
                   "#{text_annotation.annotation_text.last_editor.user_name}," \
                   "#{text_annotation.annotation_text.creator.user_name}," \
                   "#{text_annotation.annotation_text.content}\n"

        expect(@controller).to receive(:send_data).with(csv_data, csv_options) {
          # to prevent a 'missing template' error
          @controller.head :ok
        }
        get_as role,
               :uncategorized_annotations,
               params: { course_id: course.id, assignment_id: assignment.id },
               format: 'csv'
      end

      it 'expects a call to send_data without editor' do
        text_annotation = create(:text_annotation, annotation_text: different_text, result: assignment_result)
        csv_data = "#{assignment.groupings.first.group.group_name}," \
                   ',' \
                   "#{text_annotation.annotation_text.creator.user_name}," \
                   "#{text_annotation.annotation_text.content}\n"
        expect(@controller).to receive(:send_data).with(csv_data, csv_options) {
          # to prevent a 'missing template' error
          @controller.head :ok
        }
        get_as role, :uncategorized_annotations,
               params: { course_id: course.id, assignment_id: assignment.id }, format: 'csv'
      end

      it 'responds with appropriate status' do
        get_as role, :uncategorized_annotations,
               params: { course_id: course.id, assignment_id: assignment.id }, format: 'csv'
        expect(response).to have_http_status(:ok)
      end

      # parse header object to check for the right disposition
      it 'sets disposition as attachment' do
        get_as role, :uncategorized_annotations,
               params: { course_id: course.id, assignment_id: assignment.id }, format: 'csv'
        d = response.header['Content-Disposition'].split.first
        expect(d).to eq 'attachment;'
      end

      # parse header object to check for the right content type
      it 'returns text/csv type' do
        get_as role, :uncategorized_annotations,
               params: { course_id: course.id, assignment_id: assignment.id }, format: 'csv'
        expect(response.media_type).to eq 'text/csv'
      end

      # parse header object to check for the right file naming convention
      it 'filename passes naming conventions' do
        get_as role, :uncategorized_annotations,
               params: { course_id: course.id, assignment_id: assignment.id }, format: 'csv'
        filename = response.header['Content-Disposition']
                           .split[1].split('"').second
        expect(filename).to eq "#{assignment.short_identifier}_one_time_annotations.csv"
      end
    end

    context 'CSV_Downloads' do
      let(:annotation_text) do
        create(:annotation_text,
               annotation_category: annotation_category)
      end
      let(:csv_data) do
        "#{annotation_category.annotation_category_name},," \
          "#{annotation_text.content}\n"
      end
      let(:csv_options) do
        { filename: "#{assignment.short_identifier}_annotations.csv",
          disposition: 'attachment' }
      end

      it_behaves_like 'role is from a different course' do
        subject do
          get_as new_role, :download,
                 params: { course_id: course.id, assignment_id: assignment.id }, format: 'csv'
        end
      end
      it 'responds with appropriate status' do
        get_as role, :download,
               params: { course_id: course.id, assignment_id: assignment.id }, format: 'csv'
        expect(response).to have_http_status(:ok)
      end

      # parse header object to check for the right disposition
      it 'sets disposition as attachment' do
        get_as role, :download,
               params: { course_id: course.id, assignment_id: assignment.id }, format: 'csv'
        d = response.header['Content-Disposition'].split.first
        expect(d).to eq 'attachment;'
      end

      it 'expects a call to send_data' do
        expect(@controller).to receive(:send_data).with(csv_data, csv_options) {
          # to prevent a 'missing template' error
          @controller.head :ok
        }
        get_as role, :download,
               params: { course_id: course.id, assignment_id: assignment.id }, format: 'csv'
      end

      # parse header object to check for the right content type
      it 'returns text/csv type' do
        get_as role, :download,
               params: { course_id: course.id, assignment_id: assignment.id }, format: 'csv'
        expect(response.media_type).to eq 'text/csv'
      end

      # parse header object to check for the right file naming convention
      it 'filename passes naming conventions' do
        get_as role, :download,
               params: { course_id: course.id, assignment_id: assignment.id }, format: 'csv'
        filename = response.header['Content-Disposition']
                           .split[1].split('"').second
        expect(filename).to eq "#{assignment.short_identifier}_annotations.csv"
      end

      it 'expects correct call to send_data when deductive information is included' do
        assignment = create(:assignment_with_deductive_annotations)
        category = assignment.annotation_categories.where.not(flexible_criterion_id: nil).first
        criterion_name = category.flexible_criterion.name
        annotation_text = category.annotation_texts.first
        csv_data = "#{category.annotation_category_name},#{criterion_name}," \
                   "#{annotation_text.content},#{annotation_text.deduction}\n"
        csv_options = { filename: "#{assignment.short_identifier}_annotations.csv",
                        disposition: 'attachment' }
        expect(@controller).to receive(:send_data).with(csv_data, csv_options) {
          # to prevent a 'missing template' error
          @controller.head :ok
        }
        get_as role, :download,
               params: { course_id: course.id, assignment_id: assignment.id }, format: 'csv'
      end
    end

    context 'YAML download' do
      it 'correctly downloads annotation_category information with deductive information' do
        assignment = create(:assignment_with_deductive_annotations)
        yml_data = AnnotationCategory.annotation_categories_to_yml(assignment.annotation_categories)
        yml_options = { filename: "#{assignment.short_identifier}_annotations.yml",
                        disposition: 'attachment' }
        expect(@controller).to receive(:send_data).with(yml_data, yml_options) {
          # to prevent a 'missing template' error
          @controller.head :ok
        }
        get_as role, :download,
               params: { course_id: course.id, assignment_id: assignment.id }, format: 'yml'
      end

      it_behaves_like 'role is from a different course' do
        subject do
          get_as new_role, :download,
                 params: { course_id: course.id, assignment_id: assignment.id }, format: 'yml'
        end
      end
    end
  end

  shared_examples 'An unauthorized user managing annotation categories' do
    describe '#show' do
      it 'should respond with 403' do
        get_as role, :show, params: { course_id: course.id, assignment_id: assignment.id, id: annotation_category.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe '#new' do
      it 'should respond with 403' do
        get_as role, :new, params: { course_id: course.id, assignment_id: assignment.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe '#new_annotation_text' do
      it 'should respond with 403' do
        get_as role, :new_annotation_text,
               params: { course_id: course.id,
                         assignment_id: assignment.id,
                         annotation_category_id: annotation_category.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe '#create' do
      it 'should respond with 403' do
        post_as role, :create,
                params: { course_id: course.id,
                          assignment_id: assignment.id,
                          annotation_category: { annotation_category_name: 'New Category' } }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe '#update' do
      it 'should respond with 403' do
        patch_as role, :update,
                 params: { assignment_id: assignment.id,
                           course_id: course.id,
                           id: annotation_category.id,
                           annotation_category: { annotation_category_name: 'Updated category' } }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe '#update_positions' do
      it 'should respond with 403' do
        cat1 = create(:annotation_category, assignment: assignment)
        cat2 = create(:annotation_category, assignment: assignment)
        post_as role, :update_positions,
                params: { course_id: course.id, assignment_id: assignment.id, annotation_category: [cat2.id, cat1.id] }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe '#destroy' do
      it 'should respond with 403' do
        delete_as role,
                  :destroy,
                  format: :js,
                  params: { course_id: course.id, assignment_id: assignment.id, id: annotation_category.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe '#create_annotation_text' do
      it 'should respond with 403' do
        post_as role, :create_annotation_text,
                params: { assignment_id: assignment.id,
                          course_id: course.id,
                          annotation_text: { content: 'New content', annotation_category_id: annotation_category.id },
                          format: :js }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'When searching for an annotation text' do
      describe '#destroy_annotation_text' do
        it 'should respond with 403' do
          text = create(:annotation_text)
          category = text.annotation_category
          delete_as role, :destroy_annotation_text,
                    params: { assignment_id: category.assessment_id,
                              course_id: course.id,
                              annotation_text_id: text.id,
                              format: :js }
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe '#update_annotation_text' do
        it 'should respond with 403' do
          text = create(:annotation_text)
          category = text.annotation_category
          put_as role, :update_annotation_text,
                 params: { assignment_id: category.assessment_id,
                           course_id: course.id,
                           annotation_text_id: text.id,
                           annotation_text: { content: 'updated content' },
                           format: :js }
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe '#upload' do
        it 'should respond with 403' do
          file_good = fixture_file_upload('annotation_categories/form_good.csv', 'text/csv')
          post_as role, :upload, params: { course_id: course.id, assignment_id: assignment.id, upload_file: file_good }
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe '#download' do
        it 'should respond with 403' do
          get_as role, :download, params: { course_id: course.id, assignment_id: assignment.id }, format: 'csv'
          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe 'When the user is instructor' do
    let(:role) { create(:instructor) }

    it_behaves_like 'An authorized user managing annotation categories'
  end

  describe 'When the user is grader' do
    context 'When the grader is allowed to manage annotations' do
      let(:role) { create(:ta, manage_assessments: true) }

      it_behaves_like 'An authorized user managing annotation categories'
    end

    context 'When the grader is not allowed to manage annotations' do
      # By default all the grader permissions are set to false
      let(:role) { create(:ta) }

      it_behaves_like 'An unauthorized user managing annotation categories'
      it_behaves_like 'A grader or instructor accessing the index or find_annotation_text routes'
    end
  end
end
