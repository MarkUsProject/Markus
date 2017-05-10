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
      @a2 = Admin.create(user_name: 'admin2',
                         last_name: 'admin2',
                         first_name: 'admin2')
    end

    let(:annotation_category) { FactoryGirl.create(:annotation_category) }
    let(:annotation_text) { FactoryGirl.create(:annotation_text) }
    let(:assignment) { FactoryGirl.create(:assignment) }
    let(:submission) { FactoryGirl.create(:submission) }
    let(:result) { FactoryGirl.create(:result, marking_state: Result::MARKING_STATES[:incomplete]) }
    let(:submission_file) { SubmissionFile.create!(submission_id: submission.id, filename: 'test.txt')}

    it 'on :add_existing_annotation' do
      post_as @a2, :add_existing_annotation,
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
      post_as @a2, :create,
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
      post_as @a2, :create,
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

  end

end
