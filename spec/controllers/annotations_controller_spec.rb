describe AnnotationsController do
  # TODO: add 'role is from a different course' shared tests to each route test below
  let(:annotation_text_oto) { create(:annotation_text, annotation_category: nil) }
  let(:annotation_text) { create(:annotation_text, annotation_category: annotation_category) }
  let(:annotation_category) { create(:annotation_category, assignment: assignment) }
  let(:notebook_submission_file) { create(:notebook_submission_file, submission: submission) }
  let(:rmd_submission_file) { create(:rmd_submission_file, submission: submission) }
  let(:pdf_submission_file) { create(:pdf_submission_file, submission: submission) }
  let(:image_submission_file) { create(:image_submission_file, submission: submission) }
  let(:submission_file) { create(:submission_file, submission: submission) }
  let(:course) { assignment.course }
  let(:assignment) { submission.assignment }
  let(:submission) { result.submission }
  let(:result) { create(:result, marking_state: Result::MARKING_STATES[:incomplete]) }

  context 'An unauthenticated user' do
    let(:annotation) { create(:text_annotation, result: result) }

    it 'on :add_existing_annotation' do
      post :add_existing_annotation, params: { course_id: course.id, submission_file_id: 1 }
      expect(response).to have_http_status(:redirect)
    end

    it 'on :create' do
      post :create, params: { course_id: course.id, result_id: result.id }
      expect(response).to have_http_status(:redirect)
    end

    it 'on :destroy' do
      delete :destroy, params: { course_id: course.id, id: annotation.id }
      expect(response).to have_http_status(:redirect)
    end

    it 'on :update' do
      put :update, params: { course_id: course.id, id: annotation.id }
      expect(response).to have_http_status(:redirect)
    end
  end

  shared_examples 'an authenticated instructor or TA' do
    describe '#add_existing_annotation' do
      it 'successfully creates a text annotation' do
        post_as user,
                :add_existing_annotation,
                params: { annotation_text_id: annotation_text.id, submission_file_id: submission_file.id, line_start: 1,
                          line_end: 1, column_start: 1, column_end: 1, result_id: result.id, course_id: course.id },
                format: :js

        expect(response).to have_http_status(:success)
        expect(result.annotations.reload.size).to eq 1
      end

      it 'successfully creates an image annotation' do
        post_as user,
                :add_existing_annotation,
                params: { annotation_text_id: annotation_text.id, submission_file_id: image_submission_file.id,
                          x1: 0, x2: 1, y1: 0, y2: 1, result_id: result.id, course_id: course.id },
                format: :js

        expect(response).to have_http_status(:success)
        expect(result.annotations.reload.size).to eq 1
      end

      it 'successfully creates an html annotation for jupyter notebook file' do
        post_as user,
                :add_existing_annotation,
                params: { annotation_text_id: annotation_text.id, submission_file_id: notebook_submission_file.id,
                          start_node: 'a', start_offset: 1, end_node: 'b', end_offset: 0, result_id: result.id,
                          course_id: course.id },
                format: :js

        expect(response).to have_http_status(:success)
        expect(result.annotations.reload.size).to eq 1
      end

      context 'when rmd_convert_enabled is true' do
        before { allow(Rails.application.config).to receive(:rmd_convert_enabled).and_return(true) }

        it 'adds an html annotation to an RMarkdown submission file' do
          post_as user,
                  :add_existing_annotation,
                  params: { annotation_text_id: annotation_text.id, submission_file_id: rmd_submission_file.id,
                            start_node: 'a', start_offset: 1, end_node: 'b', end_offset: 0, result_id: result.id,
                            course_id: course.id },
                  format: :js

          expect(response).to have_http_status(:success)
          expect(result.annotations.reload.size).to eq 1
        end
      end

      context 'when rmd_convert_enabled is false' do
        before { allow(Rails.application.config).to receive(:rmd_convert_enabled).and_return(false) }

        it 'adds a text annotation to an RMarkdown submission file' do
          post_as user,
                  :add_existing_annotation,
                  params: { annotation_text_id: annotation_text.id, submission_file_id: rmd_submission_file.id,
                            line_start: 1, line_end: 1, column_start: 1, column_end: 1, result_id: result.id,
                            course_id: course.id },
                  format: :js

          expect(response).to have_http_status(:success)
          expect(result.annotations.reload.size).to eq 1
        end
      end

      it 'successfully creates a PDF annotation' do
        post_as user,
                :add_existing_annotation,
                params: { annotation_text_id: annotation_text.id, submission_file_id: pdf_submission_file.id,
                          x1: 0, x2: 1, y1: 0, y2: 1, page: 1, result_id: result.id, course_id: course.id },
                format: :js

        expect(response).to have_http_status(:success)
        expect(result.annotations.reload.size).to eq 1
      end
    end

    describe '#create' do
      it 'successfully creates a text annotation' do
        post_as user,
                :create,
                params: { content: annotation_text.content, category_id: annotation_category.id,
                          submission_file_id: submission_file.id, line_start: 1, line_end: 1, column_start: 1,
                          column_end: 1, result_id: result.id, assignment_id: assignment.id, course_id: course.id },
                format: :js

        expect(response).to have_http_status(:success)
        expect(result.annotations.reload.size).to eq 1
      end

      it 'successfully uses an existing one-time-only text annotation' do
        post_as user,
                :create,
                params: { content: annotation_text_oto.content,
                          annotation_text_id: annotation_text_oto.id, category_id: nil,
                          submission_file_id: submission_file.id, line_start: 1, line_end: 1, column_start: 1,
                          column_end: 1, result_id: result.id, assignment_id: assignment.id, course_id: course.id },
                format: :js

        expect(response).to have_http_status(:success)
        expect(result.annotations.reload.size).to eq 1
        expect(AnnotationText.all.size).to eq 2

        post_as user,
                :create,
                params: { content: annotation_text_oto.content,
                          annotation_text_id: annotation_text_oto.id, category_id: nil,
                          submission_file_id: submission_file.id, line_start: 2, line_end: 2, column_start: 2,
                          column_end: 2, result_id: result.id, assignment_id: assignment.id, course_id: course.id },
                format: :js
        expect(response).to have_http_status(:success)
        expect(result.annotations.reload.size).to eq 2
        expect(AnnotationText.all.size).to eq 3
      end

      it 'successfully uses an existing text annotation from a category' do
        post_as user,
                :create,
                params: { content: annotation_text.content,
                          annotation_text_id: annotation_text.id, category_id: annotation_category.id,
                          submission_file_id: submission_file.id, line_start: 1, line_end: 1, column_start: 1,
                          column_end: 1, result_id: result.id, assignment_id: assignment.id, course_id: course.id },
                format: :js

        expect(response).to have_http_status(:success)
        expect(result.annotations.reload.size).to eq 1
        expect(AnnotationText.all.size).to eq 1

        post_as user,
                :create,
                params: { content: annotation_text.content,
                          annotation_text_id: annotation_text.id, category_id: annotation_category.id,
                          submission_file_id: submission_file.id, line_start: 2, line_end: 2, column_start: 2,
                          column_end: 2, result_id: result.id, assignment_id: assignment.id, course_id: course.id },
                format: :js
        expect(response).to have_http_status(:success)
        expect(result.annotations.reload.size).to eq 2
        expect(AnnotationText.all.size).to eq 1
      end

      it 'successfully uses an existing one-time only text annotation and adds it to a category' do
        post_as user,
                :create,
                params: { content: annotation_text_oto.content,
                          annotation_text_id: annotation_text_oto.id, category_id: annotation_category.id,
                          submission_file_id: submission_file.id, line_start: 1, line_end: 1, column_start: 1,
                          column_end: 1, result_id: result.id, assignment_id: assignment.id, course_id: course.id },
                format: :js

        expect(response).to have_http_status(:success)
        expect(result.annotations.reload.size).to eq 1
        expect(annotation_text_oto.reload.annotation_category_id).to eq annotation_category.id
      end

      it 'successfully uses an existing text annotation switches it to a different category' do
        new_category = create(:annotation_category, assignment: assignment)
        post_as user,
                :create,
                params: { content: annotation_text.content,
                          annotation_text_id: annotation_text.id, category_id: new_category.id,
                          submission_file_id: submission_file.id, line_start: 1, line_end: 1, column_start: 1,
                          column_end: 1, result_id: result.id, assignment_id: assignment.id, course_id: course.id },
                format: :js

        expect(response).to have_http_status(:success)
        expect(result.annotations.reload.size).to eq 1
        expect(annotation_text.reload.annotation_category_id).to eq new_category.id
      end

      it 'successfully uses an existing text annotation to create a new one-time only annotation' do
        post_as user,
                :create,
                params: { content: annotation_text.content,
                          annotation_text_id: annotation_text.id, category_id: nil,
                          submission_file_id: submission_file.id, line_start: 1, line_end: 1, column_start: 1,
                          column_end: 1, result_id: result.id, assignment_id: assignment.id, course_id: course.id },
                format: :js

        expect(response).to have_http_status(:success)
        expect(result.annotations.reload.size).to eq 1
        expect(result.annotations.first.annotation_text.annotation_category_id).to be_nil

        # Existing annotation text wasn't changed
        expect(annotation_text.reload.annotation_category_id).to eq annotation_category.id
      end

      it 'successfully creates an image annotation' do
        post_as user,
                :create,
                params: { content: annotation_text.content, category_id: annotation_category.id,
                          submission_file_id: image_submission_file.id, x1: 0, x2: 1, y1: 0, y2: 1,
                          result_id: result.id, assignment_id: assignment.id, course_id: course.id },
                format: :js

        expect(response).to have_http_status(:ok)
        expect(result.annotations.reload.size).to eq 1
      end

      it 'successfully creates a PDF annotation' do
        post_as user,
                :create,
                params: { content: annotation_text.content, category_id: annotation_category.id,
                          submission_file_id: pdf_submission_file.id, x1: 0, x2: 1, y1: 0, y2: 1, page: 1,
                          result_id: result.id, assignment_id: assignment.id, course_id: course.id },
                format: :js

        expect(response).to have_http_status(:ok)
        expect(result.annotations.reload.size).to eq 1
      end

      it 'successfully creates an html annotation for a jupyter notebook file' do
        post_as user,
                :create,
                params: { content: annotation_text.content, category_id: annotation_category.id,
                          submission_file_id: notebook_submission_file.id, start_node: 'a', start_offset: 1,
                          end_node: 'b', end_offset: 0, result_id: result.id, assignment_id: assignment.id,
                          course_id: course.id },
                format: :js

        expect(response).to have_http_status(:success)
        expect(result.annotations.reload.size).to eq 1
      end

      context 'when rmd_convert_enabled is true' do
        before { allow(Rails.application.config).to receive(:rmd_convert_enabled).and_return(true) }

        it 'adds an html annotation to an RMarkdown submission file' do
          post_as user,
                  :add_existing_annotation,
                  params: { annotation_text_id: annotation_text.id, submission_file_id: rmd_submission_file.id,
                            start_node: 'a', start_offset: 1, end_node: 'b', end_offset: 0, result_id: result.id,
                            course_id: course.id },
                  format: :js

          expect(response).to have_http_status(:success)
          expect(result.annotations.reload.size).to eq 1
        end
      end

      context 'when rmd_convert_enabled is false' do
        before { allow(Rails.application.config).to receive(:rmd_convert_enabled).and_return(false) }

        it 'adds a text annotation to an RMarkdown submission file' do
          post_as user,
                  :add_existing_annotation,
                  params: { annotation_text_id: annotation_text.id, submission_file_id: rmd_submission_file.id,
                            line_start: 1, line_end: 1, column_start: 1, column_end: 1, result_id: result.id,
                            course_id: course.id },
                  format: :js

          expect(response).to have_http_status(:success)
          expect(result.annotations.reload.size).to eq 1
        end
      end

      it 'successfully creates an annotation where the deduction is not specified but a category with criterion is' do
        assignment = create(:assignment_with_deductive_annotations)
        category = assignment.annotation_categories.where.not(flexible_criterion_id: nil).first
        result = assignment.groupings.first.current_result
        submission_file = create(:submission_file, submission: result.submission)
        post_as user,
                :create,
                params: { content: 'I like icecream!', category_id: category.id,
                          submission_file_id: submission_file.id, line_start: 1, line_end: 1, column_start: 1,
                          column_end: 1, result_id: result.id, assignment_id: assignment.id, course_id: course.id },
                format: :js

        expect(response).to have_http_status(:success)
        expect(result.annotations.reload.size).to eq 2
        expect(result.annotations.joins(:annotation_text).where('annotation_texts.deduction': 0).size).to eq 1
      end
    end

    describe '#destroy' do
      it 'destroys the annotation when there is only one annotation for the result' do
        anno = create(
          :text_annotation,
          annotation_text: annotation_text,
          submission_file: submission_file,
          creator: user,
          result: result
        )
        delete_as user,
                  :destroy,
                  params: { id: anno.id, submission_file_id: submission_file.id, assignment_id: assignment.id,
                            result_id: result.id, course_id: course.id },
                  format: :js

        expect(response).to have_http_status(:success)
        expect(result.annotations.reload.size).to eq 0
      end

      it 'destroys an annotation when there are multiple annotations for the result' do
        annotations = []
        3.times do |_|
          annotations << create(
            :text_annotation,
            annotation_text: annotation_text,
            submission_file: submission_file,
            creator: user,
            result: result
          )
        end

        delete_as user,
                  :destroy,
                  params: { id: annotations[1].id, submission_file_id: submission_file.id, assignment_id: assignment.id,
                            result_id: result.id, course_id: course.id },
                  format: :js

        expect(response).to have_http_status(:success)

        # Check that there are only two annotations remaining.
        expect(result.annotations.reload.size).to eq 2

        # Check that the annotations were renumbered.
        expect(result.annotations.pluck(:annotation_number).sort).to eq [1, 2]
      end

      it 'does not destroy the associated annotation text if the text belongs to an annotation category' do
        anno = create(
          :text_annotation,
          annotation_text: annotation_text,
          submission_file: submission_file,
          creator: user,
          result: result
        )
        delete_as user,
                  :destroy,
                  params: { id: anno.id, submission_file_id: submission_file.id, assignment_id: assignment.id,
                            result_id: result.id, course_id: course.id },
                  format: :js

        expect(AnnotationText.exists?(annotation_text.id)).to be true
      end

      it 'destroys the associated annotation text if the text is one time only' do
        new_text = create(:annotation_text, annotation_category: nil)
        anno = create(
          :text_annotation,
          annotation_text: new_text,
          submission_file: submission_file,
          creator: user,
          result: result
        )
        delete_as user,
                  :destroy,
                  params: { id: anno.id, submission_file_id: submission_file.id, assignment_id: assignment.id,
                            result_id: result.id, course_id: course.id },
                  format: :js

        expect(AnnotationText.exists?(new_text.id)).to be false
      end
    end

    describe '#update' do
      it 'successfully updates annotation text' do
        anno = create(
          :text_annotation,
          submission_file: submission_file,
          creator: user,
          result: result
        )
        put_as user,
               :update,
               params: { id: anno.id, assignment_id: assignment.id, submission_file_id: submission_file.id,
                         result_id: result.id, content: 'new content', course_id: course.id },
               format: :js
        expect(response).to have_http_status(:success)
        expect(anno.annotation_text.reload.content).to eq 'new content'
      end

      it 'successfully updates a singular annotation text' do
        anno_text = create(:annotation_text, annotation_category: annotation_category)
        anno1 = create(
          :text_annotation,
          annotation_text: anno_text,
          submission_file: submission_file,
          creator: user,
          result: result
        )
        anno2 = create(
          :text_annotation,
          annotation_text: anno_text,
          submission_file: submission_file,
          creator: user,
          result: result
        )
        put_as user,
               :update,
               params: { id: anno1.id, assignment_id: assignment.id, submission_file_id: submission_file.id,
                         result_id: result.id, content: 'new content', annotation_text: { change_all: '0' },
                         course_id: course.id },
               format: :js
        expect(response).to have_http_status(:success)
        expect(anno1.reload.annotation_text.reload.content).to eq 'new content'
        expect(anno2.reload.annotation_text.reload.content).not_to eq 'new content'
      end
    end
  end

  describe 'an authenticated instructor' do
    let!(:user) { create(:instructor) }

    it_behaves_like 'an authenticated instructor or TA'

    describe 'accessing annotations for results in an assignment with deductive annotations' do
      let(:assignment) { create(:assignment_with_deductive_annotations) }
      let(:result) { assignment.groupings.first.current_result }
      let(:annotation) { result.annotations.first }

      it 'can update a deductive annotation\'s content' do
        post_as user,
                :update,
                params: { content: 'New content!',
                          id: annotation.id,
                          result_id: result.id,
                          course_id: course.id,
                          assignment_id: assignment.id },
                format: :js
        expect(annotation.reload.annotation_text.content).to eq 'New content!'
      end

      it 'cannot update deductive annotation content if that content has been applied to released results' do
        assignment.groupings.first.current_result.update(released_to_students: true)
        other_grouping = assignment.reload.groupings.joins(submissions: :results)
                                   .where(results: { released_to_students: false }).first
        post_as user,
                :update,
                params: { content: 'New content!',
                          id: annotation.id,
                          course_id: course.id,
                          result_id: other_grouping.current_result.id,
                          assignment_id: assignment.id },
                format: :js
        expect(response).to have_http_status(:bad_request)
        expect(annotation.reload.annotation_text.content).not_to eq 'New content!'
      end

      it 'can destroy a deductive annotation' do
        post_as user,
                :destroy,
                params: { id: annotation.id,
                          result_id: result.id,
                          course_id: course.id,
                          assignment_id: assignment.id },
                format: :js
        expect(result.reload.annotations.size).to eq 0
      end

      it 'can destroy a deductive annotation when criteria assigned to graders' do
        assignment.assignment_properties.update(assign_graders_to_criteria: true)
        post_as user,
                :destroy,
                params: { id: annotation.id,
                          result_id: result.id,
                          course_id: course.id,
                          assignment_id: assignment.id },
                format: :js
        expect(result.reload.annotations.size).to eq 0
      end
    end
  end

  describe 'an authenticated TA' do
    let!(:user) { create(:ta) }

    it_behaves_like 'an authenticated instructor or TA'

    describe 'accessing annotations for results in an assignment with deductive annotations' do
      let(:assignment) { create(:assignment_with_deductive_annotations) }
      let(:result) { assignment.groupings.first.current_result }
      let(:annotation) { result.annotations.first }

      it 'cannot update a deductive annotation' do
        post_as user,
                :update,
                params: { content: 'New content!',
                          id: annotation.id,
                          result_id: result.id,
                          course_id: course.id,
                          assignment_id: assignment.id },
                format: :js
        expect(response).to have_http_status(:bad_request)
        expect(annotation.reload.annotation_text.content).not_to eq 'New content!'
      end

      it 'cannot update a deductive annotation even if assigned to its criterion' do
        assignment.assignment_properties.update(assign_graders_to_criteria: true)
        create(:criterion_ta_association,
               criterion: annotation.annotation_text.annotation_category.flexible_criterion,
               ta: user)
        post_as user,
                :update,
                params: { content: 'New content!',
                          id: annotation.id,
                          result_id: result.id,
                          course_id: course.id,
                          assignment_id: assignment.id },
                format: :js
        expect(response).to have_http_status(:bad_request)
        expect(annotation.reload.annotation_text.content).not_to eq 'New content!'
      end

      it 'cannot destroy a deductive annotation if unassigned to the annotation\'s criterion' do
        other_criterion = create(:rubric_criterion, assignment: assignment)
        assignment.assignment_properties.update(assign_graders_to_criteria: true)
        create(:criterion_ta_association, criterion: other_criterion, ta: user)
        post_as user,
                :destroy,
                params: { id: annotation.id,
                          result_id: result.id,
                          course_id: course.id,
                          assignment_id: assignment.id },
                format: :js
        expect(response).to have_http_status(:bad_request)
        expect(result.reload.annotations.size).to eq 1
      end

      it 'can destroy a deductive annotation if assigned to the annotation\'s criterion' do
        assignment.assignment_properties.update(assign_graders_to_criteria: true)
        create(:criterion_ta_association, criterion: assignment.criteria
                                                       .where(type: 'FlexibleCriterion').first, ta: user)
        post_as user,
                :destroy,
                params: { id: annotation.id,
                          result_id: result.id,
                          course_id: course.id,
                          assignment_id: assignment.id },
                format: :js
        expect(result.reload.annotations.size).to eq 0
      end

      it 'cannot destroy a deductive annotation if unassigned to any criteria when assignment does assign criteria' do
        assignment.assignment_properties.update(assign_graders_to_criteria: true)
        post_as user,
                :destroy,
                params: { id: annotation.id,
                          result_id: result.id,
                          course_id: course.id,
                          assignment_id: assignment.id },
                format: :js
        expect(response).to have_http_status(:bad_request)
        expect(result.reload.annotations.size).to eq 1
      end

      it 'can destroy a deductive annotation when assignment does not assign criteria' do
        post_as user,
                :destroy,
                params: { id: annotation.id,
                          result_id: result.id,
                          course_id: course.id,
                          assignment_id: assignment.id },
                format: :js
        expect(result.reload.annotations.size).to eq 0
      end
    end
  end

  context 'An authenticated and authorized Student doing a POST' do
    let(:user) { create(:student) }

    describe '#add_existing_annotation' do
      it 'returns a :not_found status code' do
        post_as user,
                :add_existing_annotation,
                params: { annotation_text_id: annotation_text.id, submission_file_id: submission_file.id, line_start: 1,
                          line_end: 1, column_start: 1, column_end: 1, result_id: result.id, course_id: course.id },
                format: :js

        expect(subject).to respond_with(:forbidden)
        expect(result.annotations.reload.size).to eq 0
      end
    end

    describe '#create' do
      it 'returns a :not_found status code' do
        post_as user,
                :create,
                params: { content: annotation_text.content, category_id: annotation_category.id,
                          submission_file_id: submission_file.id, line_start: 1, line_end: 1, column_start: 1,
                          column_end: 1, result_id: result.id, assignment_id: assignment.id, course_id: course.id },
                format: :js

        expect(subject).to respond_with(:forbidden)
        expect(result.annotations.reload.size).to eq 0
      end
    end

    describe '#destroy' do
      it 'returns a :not_found status code' do
        anno = create(
          :text_annotation,
          annotation_text: annotation_text,
          submission_file: submission_file,
          result: result
        )
        delete_as user,
                  :destroy,
                  params: { id: anno.id, submission_file_id: submission_file.id, assignment_id: assignment.id,
                            result_id: result.id, course_id: course.id },
                  format: :js

        expect(subject).to respond_with(:forbidden)
        expect(result.annotations.reload.size).to eq 1
      end
    end

    describe '#update' do
      it 'returns a :not_found status code' do
        anno = create(
          :text_annotation,
          submission_file: submission_file,
          creator: user,
          result: result
        )
        put_as user,
               :update,
               params: { id: anno.id, assignment_id: assignment.id, submission_file_id: submission_file.id,
                         result_id: result.id, content: 'new content', course_id: course.id },
               format: :js
        expect(subject).to respond_with(:forbidden)
        expect(anno.annotation_text.reload.content).not_to eq 'new content'
      end
    end
  end
end
