require 'spec_helper'

describe AnnotationsController do

  context 'An unauthenticated and unauthorized user doing a GET' do

    # Since we are not authenticated and authorized, we should be redirected
    # to the login page

    it 'on :add_existing_annotation' do
      get :add_existing_annotation, submission_file_id: 1
      expect(response).to be_redirect
    end

    it 'on :create' do
      get :create, id: 1
      expect(response).to be_redirect
    end

    it 'on :destroy' do
      delete :destroy, id: 1
      expect(response).to be_redirect
    end

    it 'on :update_annotation' do
      get :update_annotation, id: 1
      expect(response).to be_redirect
    end

  end # end context unauthenticated/unauthorized user GET

  context 'An unauthenticated and unauthorized user doing a POST' do

    # Since we are not authenticated and authorized, we should be redirected
    # to the login page

    it 'on :add_existing_annotation' do
      post :add_existing_annotation, submission_file_id: 1
      expect(response).to be_redirect
    end

    it 'on :create' do
      post :create, id: 1
      expect(response).to be_redirect
    end

    it 'on :destroy' do
      post :destroy, id: 1
      expect(response).to be_redirect
    end

    it 'on :update_annotation' do
      post :update_annotation, id: 1
      expect(response).to be_redirect
    end

  end

  context 'An authenticated and authorized admin doing a POST' do
    before :each do
      # Authenticate user is not timed out, and has administrator rights.
      @a = Admin.create(user_name: 'admin',
                         last_name: 'admin',
                         first_name: 'admin')
    end

    let(:annotation_category) { FactoryGirl.create(:annotation_category) }
    let(:annotation_text) { FactoryGirl.create(:annotation_text) }
    let(:assignment) { FactoryGirl.create(:assignment) }
    let(:submission) { FactoryGirl.create(:submission) }
    let(:result) { FactoryGirl.create(:result, marking_state: Result::MARKING_STATES[:incomplete]) }
    let(:submission_file) { SubmissionFile.create!(submission_id: submission.id, filename: 'test.txt')}

    it 'on :add_existing_annotation' do
      post_as @a, :add_existing_annotation,
              { format: :js,
                creator: :current_user,
                annotation_text_id: annotation_text.id,
                submission_file_id: submission_file.id,
                line_start: 1, line_end: 1,
                column_start: 1, column_end: 1,
                result_id: result.id,
                assignment_id: assignment.id}
      expect(response.status).to eq(200)
      expect(assigns(:submission_file)).to be_truthy
      expect(assigns(:annotation)).to be_truthy
      expect(assigns(:annotations)).to be_truthy
      expect(response).to render_template('add_existing_annotation')
    end # End context :add_existing_annotation

    it 'on :create to make a text annotation' do
      post_as @a, :create,
              { format: :js,
                content: annotation_text.content,
                category_id: annotation_category.id,
                submission_file_id: submission_file.id,
                line_start: 1, line_end: 1,
                column_start: 1, column_end: 1,
                annotation_type: 'text',
                result_id: result.id,
                assignment_id: assignment.id}
      expect(response.status).to eq(200)
      expect(assigns(:submission_file)).to be_truthy
      expect(assigns(:annotation)).to be_truthy
      expect(assigns(:annotations)).to be_truthy
      expect(response).to render_template('create')
    end # End context :create text

    it 'on :create to make an image annotation' do
      post_as @a, :create,
              { format: :js,
                content: annotation_text.content,
                category_id: annotation_category.id,
                submission_file_id: submission_file.id,
                x1: 0, x2: 1, y1: 0, y2: 1,
                annotation_type: 'image',
                result_id: result.id,
                assignment_id: assignment.id}
      expect(response.status).to eq(200)
      expect(assigns(:submission_file)).to be_truthy
      expect(assigns(:annotation)).to be_truthy
      expect(assigns(:annotations)).to be_truthy
      expect(response).to render_template('create')
    end # End context :create image

    it 'on :destroy' do
      anno = TextAnnotation.create!({
               line_start: 1, line_end: 1,
               column_start: 1, column_end: 1,
               annotation_text_id: annotation_text.id,
               submission_file_id:  submission_file.id,
               annotation_number: 1,
               is_remark: false,
               creator: @a,
               result_id: result.id})
      post_as @a, :destroy,
              { format: :js,
                id: anno.id,
                submission_file_id: submission_file.id,
                assignment_id: assignment.id,
                result_id: result.id}
      expect(response.status).to eq(200)
      expect(response).to render_template('destroy')
    end # End context :destroy

    it 'on :update_annotation' do
      anno = TextAnnotation.create!({
              line_start: 1, line_end: 1,
              column_start: 1, column_end: 1,
              annotation_text_id: annotation_text.id,
              submission_file_id:  submission_file.id,
              annotation_number: 1,
              is_remark: false,
              creator: @a,
              result_id: result.id})
      put_as @a, :update_annotation,
             format: :js,
             id: anno.id,
             assignment_id: assignment.id,
             submission_file_id: submission_file.id,
             result_id: result.id,
             content: annotation_text.content
      expect(response.status).to eq(200)
      expect(response).to render_template('update_annotation')
    end # End context :update_annotation

  end #End context admin POST

  context 'An authenticated and authorized TA doing a POST' do
    before :each do
      # Authenticate user is not timed out, and has TA rights.
      @ta = Ta.create(user_name: 'ta',
                       last_name: 'ta',
                       first_name: 'ta')
    end

    let(:annotation_category) { FactoryGirl.create(:annotation_category) }
    let(:annotation_text) { FactoryGirl.create(:annotation_text) }
    let(:assignment) { FactoryGirl.create(:assignment) }
    let(:submission) { FactoryGirl.create(:submission) }
    let(:result) { FactoryGirl.create(:result, marking_state: Result::MARKING_STATES[:incomplete]) }
    let(:submission_file) { SubmissionFile.create!(submission_id: submission.id, filename: 'test.txt')}

    it 'on :add_existing_annotation' do
      post_as @ta, :add_existing_annotation,
              { format: :js,
                creator: :current_user,
                annotation_text_id: annotation_text.id,
                submission_file_id: submission_file.id,
                line_start: 1, line_end: 1,
                column_start: 1, column_end: 1,
                result_id: result.id,
                assignment_id: assignment.id}
      expect(response.status).to eq(200)
      expect(assigns(:submission_file)).to be_truthy
      expect(assigns(:annotation)).to be_truthy
      expect(assigns(:annotations)).to be_truthy
      expect(response).to render_template('add_existing_annotation')
    end # End context :add_existing_annotation

    it 'on :create to make a text annotation' do
      post_as @ta, :create,
              { format: :js,
                content: annotation_text.content,
                category_id: annotation_category.id,
                submission_file_id: submission_file.id,
                line_start: 1, line_end: 1,
                column_start: 1, column_end: 1,
                annotation_type: 'text',
                result_id: result.id,
                assignment_id: assignment.id}
      expect(response.status).to eq(200)
      expect(assigns(:submission_file)).to be_truthy
      expect(assigns(:annotation)).to be_truthy
      expect(assigns(:annotations)).to be_truthy
      expect(response).to render_template('create')
    end # End context :create text

    it 'on :create to make an image annotation' do
      post_as @ta, :create,
              { format: :js,
                content: annotation_text.content,
                category_id: annotation_category.id,
                submission_file_id: submission_file.id,
                x1: 0, x2: 1, y1: 0, y2: 1,
                annotation_type: 'image',
                result_id: result.id,
                assignment_id: assignment.id}
      expect(response.status).to eq(200)
      expect(assigns(:submission_file)).to be_truthy
      expect(assigns(:annotation)).to be_truthy
      expect(assigns(:annotations)).to be_truthy
      expect(response).to render_template('create')
    end # End context :create image

    it 'on :destroy' do
      anno = TextAnnotation.create!({
              line_start: 1, line_end: 1,
              column_start: 1, column_end: 1,
              annotation_text_id: annotation_text.id,
              submission_file_id:  submission_file.id,
              annotation_number: 1,
              is_remark: false,
              creator: @ta,
              result_id: result.id})
      post_as @ta, :destroy,
              { format: :js,
                id: anno.id,
                submission_file_id: submission_file.id,
                assignment_id: assignment.id,
                result_id: result.id}
      expect(response.status).to eq(200)
      expect(response).to render_template('destroy')
    end # End context :destroy

    it 'on :update_annotation' do
      anno = TextAnnotation.create!({
              line_start: 1, line_end: 1,
              column_start: 1, column_end: 1,
              annotation_text_id: annotation_text.id,
              submission_file_id:  submission_file.id,
              annotation_number: 1,
              is_remark: false,
              creator: @ta,
              result_id: result.id})
      put_as @ta, :update_annotation,
             format: :js,
             id: anno.id,
             assignment_id: assignment.id,
             submission_file_id: submission_file.id,
             result_id: result.id,
             content: annotation_text.content
      expect(response.status).to eq(200)
      expect(response).to render_template('update_annotation')
    end # End context :update_annotation

  end #End context TA POST

  context 'An authenticated and authorized Student doing a POST' do
    before :each do
      # A student should get a 404 even if they do everything right
      @stu = Student.create(user_name: 'sta',
                      last_name: 'ta',
                      first_name: 'ta')
    end

    let(:annotation_category) { FactoryGirl.create(:annotation_category) }
    let(:annotation_text) { FactoryGirl.create(:annotation_text) }
    let(:assignment) { FactoryGirl.create(:assignment) }
    let(:submission) { FactoryGirl.create(:submission) }
    let(:result) { FactoryGirl.create(:result, marking_state: Result::MARKING_STATES[:incomplete]) }
    let(:submission_file) { SubmissionFile.create!(submission_id: submission.id, filename: 'test.txt')}

    it 'on :add_existing_annotation' do
      post_as @stu, :add_existing_annotation,
              { format: :js,
                creator: :current_user,
                annotation_text_id: annotation_text.id,
                submission_file_id: submission_file.id,
                line_start: 1, line_end: 1,
                column_start: 1, column_end: 1,
                result_id: result.id,
                assignment_id: assignment.id}
      expect(response.status).to eq(404)
    end # End context :add_existing_annotation

    it 'on :create to make a text annotation' do
      post_as @stu, :create,
              { format: :js,
                content: annotation_text.content,
                category_id: annotation_category.id,
                submission_file_id: submission_file.id,
                line_start: 1, line_end: 1,
                column_start: 1, column_end: 1,
                annotation_type: 'text',
                result_id: result.id,
                assignment_id: assignment.id}
      expect(response.status).to eq(404)
    end # End context :create text

    it 'on :create to make an image annotation' do
      post_as @stu, :create,
              { format: :js,
                content: annotation_text.content,
                category_id: annotation_category.id,
                submission_file_id: submission_file.id,
                x1: 0, x2: 1, y1: 0, y2: 1,
                annotation_type: 'image',
                result_id: result.id,
                assignment_id: assignment.id}
      expect(response.status).to eq(404)
    end # End context :create image

    it 'on :destroy' do
      anno = TextAnnotation.create!({
                line_start: 1, line_end: 1,
                column_start: 1, column_end: 1,
                annotation_text_id: annotation_text.id,
                submission_file_id:  submission_file.id,
                annotation_number: 1,
                is_remark: false,
                creator: @stu,
                result_id: result.id})
      post_as @stu, :destroy,
              { format: :js,
                id: anno.id,
                submission_file_id: submission_file.id,
                assignment_id: assignment.id,
                result_id: result.id}
      expect(response.status).to eq(404)
    end # End context :destroy

    it 'on :update_annotation' do
      anno = TextAnnotation.create!({
                line_start: 1, line_end: 1,
                column_start: 1, column_end: 1,
                annotation_text_id: annotation_text.id,
                submission_file_id:  submission_file.id,
                annotation_number: 1,
                is_remark: false,
                creator: @stu,
                result_id: result.id})
      put_as @stu, :update_annotation,
             format: :js,
             id: anno.id,
             assignment_id: assignment.id,
             submission_file_id: submission_file.id,
             result_id: result.id,
             content: annotation_text.content
      expect(response.status).to eq(404)
    end # End context :update_annotation

  end #End context Student POST

end
