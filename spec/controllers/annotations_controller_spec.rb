describe AnnotationsController do

  context 'An unauthenticated user' do
    it 'on :add_existing_annotation' do
      post :add_existing_annotation, params: { submission_file_id: 1 }
      assert_response :redirect
    end

    it 'on :create' do
      post :create, params: { id: 1 }
      assert_response :redirect
    end

    it 'on :destroy' do
      delete :destroy, params: { id: 1 }
      assert_response :redirect
    end

    it 'on :update' do
      put :update, params: { id: 1 }
      assert_response :redirect
    end
  end

  let(:result) { create(:result, marking_state: Result::MARKING_STATES[:incomplete]) }
  let(:submission) { result.submission }
  let(:assignment) { submission.assignment }
  let(:submission_file) { create(:submission_file, submission: submission) }
  let(:image_submission_file) { create(:image_submission_file, submission: submission) }
  let(:pdf_submission_file) { create(:pdf_submission_file, submission: submission) }
  let(:annotation_category) { create(:annotation_category, assignment: assignment) }
  let(:annotation_text) { create(:annotation_text, annotation_category: annotation_category) }

  shared_examples 'an authenticated admin or TA' do
    describe '#add_existing_annotation' do
      it 'successfully creates a text annotation' do
        post_as user,
                :add_existing_annotation,
                params: { annotation_text_id: annotation_text.id, submission_file_id: submission_file.id, line_start: 1,
                          line_end: 1, column_start: 1, column_end: 1, result_id: result.id },
                format: :js

        assert_response :success
        expect(result.annotations.reload.size).to eq 1
      end

      it 'successfully creates an image annotation' do
        post_as user,
                :add_existing_annotation,
                params: { annotation_text_id: annotation_text.id, submission_file_id: image_submission_file.id,
                          x1: 0, x2: 1, y1: 0, y2: 1, result_id: result.id },
                format: :js

        assert_response :success
        expect(result.annotations.reload.size).to eq 1
      end

      it 'successfully creates a PDF annotation' do
        post_as user,
                :add_existing_annotation,
                params: { annotation_text_id: annotation_text.id, submission_file_id: pdf_submission_file.id,
                          x1: 0, x2: 1, y1: 0, y2: 1, page: 1, result_id: result.id },
                format: :js

        assert_response :success
        expect(result.annotations.reload.size).to eq 1
      end
    end

    describe '#new' do
      it 'renders the correct template' do
        get_as user,
               :new,
               params: { result_id: result.id, assignment_id: assignment.id },
               format: :js

        assert_response :success
        expect(response).to render_template('new')
      end
    end

    describe '#create' do
      it 'successfully creates a text annotation' do
        post_as user,
                :create,
                params: { content: annotation_text.content, category_id: annotation_category.id,
                          submission_file_id: submission_file.id, line_start: 1, line_end: 1, column_start: 1,
                          column_end: 1, result_id: result.id, assignment_id: assignment.id },
                format: :js

        assert_response :success
        expect(result.annotations.reload.size).to eq 1
      end

      it 'successfully creates an image annotation' do
        post_as user,
                :create,
                params: { content: annotation_text.content, category_id: annotation_category.id,
                          submission_file_id: image_submission_file.id, x1: 0, x2: 1, y1: 0, y2: 1,
                          result_id: result.id, assignment_id: assignment.id },
                format: :js

        expect(response.status).to eq(200)
        expect(result.annotations.reload.size).to eq 1
      end

      it 'successfully creates a PDF annotation' do
        post_as user,
                :create,
                params: { content: annotation_text.content, category_id: annotation_category.id,
                          submission_file_id: pdf_submission_file.id, x1: 0, x2: 1, y1: 0, y2: 1, page: 1,
                          result_id: result.id, assignment_id: assignment.id },
                format: :js

        expect(response.status).to eq(200)
        expect(result.annotations.reload.size).to eq 1
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
                            result_id: result.id },
                  format: :js

        assert_response :success
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
                            result_id: result.id },
                  format: :js

        assert_response :success

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
                            result_id: result.id },
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
                            result_id: result.id },
                  format: :js

        expect(AnnotationText.exists?(new_text.id)).to be false
      end
    end

    describe '#edit' do
      it 'renders the correct template' do
        anno = create(
          :text_annotation,
          submission_file: submission_file,
          creator: user,
          result: result
        )
        get_as user,
               :edit,
               params: { id: anno.id, result_id: result.id, assignment_id: assignment.id },
               format: :js

        assert_response :success
        expect(response).to render_template('edit')
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
                         result_id: result.id, content: 'new content' },
               format: :js
        assert_response :success
        expect(anno.annotation_text.reload.content).to eq 'new content'
      end
    end
  end

  describe 'an authenticated admin' do
    let!(:user) { create(:admin) }
    include_examples 'an authenticated admin or TA'
  end

  describe 'an authenticated TA' do
    let!(:user) { create(:admin) }
    include_examples 'an authenticated admin or TA'
  end

  context 'An authenticated and authorized Student doing a POST' do
    let(:user) { create(:student) }

    describe '#add_existing_annotation' do
      it 'returns a :not_found status code' do
        post_as user,
                :add_existing_annotation,
                params: { annotation_text_id: annotation_text.id, submission_file_id: submission_file.id, line_start: 1,
                          line_end: 1, column_start: 1, column_end: 1, result_id: result.id },
                format: :js

        assert_response :not_found
        expect(result.annotations.reload.size).to eq 0
      end
    end

    describe '#create' do
      it 'returns a :not_found status code' do
        post_as user,
                :create,
                params: { content: annotation_text.content, category_id: annotation_category.id,
                          submission_file_id: submission_file.id, line_start: 1, line_end: 1, column_start: 1,
                          column_end: 1, result_id: result.id, assignment_id: assignment.id },
                format: :js

        assert_response :not_found
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
                            result_id: result.id },
                  format: :js

        assert_response :not_found
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
                         result_id: result.id, content: 'new content' },
               format: :js
        assert_response :not_found
        expect(anno.annotation_text.reload.content).to_not eq 'new content'
      end
    end
  end
end
