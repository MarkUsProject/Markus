require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

require 'shoulda'
require 'machinist'


class AnnotationsControllerTest < AuthenticatedControllerTest

  context 'An unauthenticated and unauthorized user doing a GET' do

    # Since we are not authenticated and authorized, we should be redirected
    # to the login page

    should 'on :add_existing_annotation' do
      get :add_existing_annotation, submission_file_id: 1
      assert_response :redirect
    end

    should 'on :create' do
      get :create, id: 1
      assert_response :redirect
    end

    should 'on :destroy' do
      delete :destroy, id: 1
      assert_response :redirect
    end

    should 'on :update_annotation' do
      get :update_annotation, id: 1
      assert_response :redirect
    end
  end # end context unauthenticated/unauthorized user GET

  context 'An unauthenticated and unauthorized user doing a POST' do

    # Since we are not authenticated and authorized, we should be redirected
    # to the login page

    should 'on :add_existing_annotation' do
      post :add_existing_annotation, id: 1
      assert_response :redirect
    end

    should 'on :create' do
      post :create, id: 1
      assert_response :redirect
    end

    should 'on :destroy' do
      post :destroy, id: 1
      assert_response :redirect
    end

    should 'on :update_annotation' do
      post :update_annotation, id: 1
      assert_response :redirect
    end
  end # end context unauthenticated/unauthorized user POST

  context 'An authenticated and authorized admin doing a POST' do
     setup do
      @user = Admin.make
      @assignment = Assignment.make
      @text_annotation = TextAnnotation.make({creator: @user})
      @category = AnnotationCategory.make
      @annotation_text = AnnotationText.make
      @submission_file = SubmissionFile.make
      @result = Result.make
    end

    should 'on :add_existing_annotation' do
      post_as @user, :add_existing_annotation,
              { format: :js,
                annotation_text_id: @annotation_text.id,
                submission_file_id: @submission_file.id,
                line_start: 1, line_end: 1,
                column_start: 1, column_end: 1,
                result_id: @result.id,
                assignment_id: @assignment.id}
      assert_response :success
      assert_not_nil assigns :submission_file
      assert_not_nil assigns :annotation
      assert_not_nil assigns :annotations
      assert render_template 'add_existing_annotation'
    end # End context :add_existing_annotation

    should 'on :create to make a text annotation' do
      post_as @user, :create,
              { format: :js,
                content: @annotation_text.content,
                category_id: @category.id,
                submission_file_id: @submission_file.id,
                line_start: 1, line_end: 1,
                column_start: 1, column_end: 1,
                annotation_type: 'text',
                result_id: @result.id,
                assignment_id: @assignment.id}
      assert_response :success
      assert_not_nil assigns :submission_file
      assert_not_nil assigns :annotation
      assert render_template 'create'
    end # End context :create text

    should 'on :create to make an image annotation' do
      post_as @user, :create,
              { format: :js,
                content: @annotation_text.content,
                category_id: @category.id,
                submission_file_id: @submission_file.id,
                x1: 0, x2: 1, y1: 0, y2: 1,
                annotation_type: 'image',
                result_id: @result.id,
                assignment_id: @assignment.id}
      assert_response :success
      assert_not_nil assigns :submission_file
      assert_not_nil assigns :annotation
      assert render_template 'create'
    end # End context :create image

    should 'on :destroy' do
      anno = TextAnnotation.make({
        line_start: 1, line_end: 1,
        annotation_text_id: @annotation_text.id,
        submission_file_id:  @submission_file.id,
        annotation_number: 1,
        result_id: @result.id})
      post_as @user, :destroy,
              { format: :js,
                id: anno.id,
                submission_file_id: @submission_file.id,
                assignment_id: @assignment.id,
                result_id: @result.id}
      assert_response :success
      assert render_template 'destroy'
    end # End context :destroy

    should 'on :update_annotation' do
      anno = TextAnnotation.make({
        line_start: 1, line_end: 1,
        annotation_text_id: @annotation_text.id,
        submission_file_id:  @submission_file.id})
      put_as @user, :update_annotation,
             format: :js,
             assignment_id: @assignment.id,
             submission_file_id: @submission_file.id,
             result_id: @result.id,
             annotation_text: { id: @annotation_text.id,
                                content: @annotation_text.content}
      assert_response :success
      assert render_template 'update_annotation'
    end # End context :update_annotation
  end #End context admin POST

  context 'An authenticated and authorized TA doing a POST' do
     setup do
      @user = Ta.make
      @assignment = Assignment.make
      @text_annotation = TextAnnotation.make({creator: @user})
      @category = AnnotationCategory.make
      @annotation_text = AnnotationText.make
      @submission_file = SubmissionFile.make
      @result = Result.make
     end

    should 'on :add_existing_annotation' do
      post_as @user, :add_existing_annotation,
              { format: :js,
                annotation_text_id: @annotation_text.id,
                submission_file_id: @submission_file.id,
                line_start: 1, line_end: 1,
                column_start: 1, column_end: 1,
                result_id: @result.id,
                assignment_id: @assignment.id}
      assert_response :success
      assert_not_nil assigns :submission_file
      assert_not_nil assigns :annotation
      assert render_template 'add_existing_annotation'
    end # End context :add_existing_annotation

    should 'on :create to make a text annotation' do
      post_as @user, :create,
              { format: :js,
                content: @annotation_text.content,
                category_id: @category.id,
                submission_file_id: @submission_file.id,
                line_start: 1, line_end: 1,
                column_start: 1, column_end: 1,
                annotation_type: 'text',
                result_id: @result.id,
                assignment_id: @assignment.id}
      assert_response :success
      assert_not_nil assigns :submission_file
      assert_not_nil assigns :annotation
      assert render_template 'create'
    end # End context :create text

    should 'create an image annotation' do
      post_as @user, :create,
              { format: :js,
                content: @annotation_text.content,
                category_id: @category.id,
                submission_file_id: @submission_file.id,
                x1: 0, x2: 1, y1: 0, y2: 1,
                annotation_type: 'image',
                result_id: @result.id,
                assignment_id: @assignment.id}
      assert_response :success
      assert_not_nil assigns :submission_file
      assert_not_nil assigns :annotation
      assert render_template 'create'
    end # End context :create image

    should 'on :destroy' do
      anno = TextAnnotation.make({
        line_start: 1, line_end: 1,
        annotation_text_id: @annotation_text.id,
        submission_file_id:  @submission_file.id,
        annotation_number: 1,
        result_id: @result.id})
      post_as @user, :destroy,
              { format: :js,
                id: anno.id,
                submission_file_id: @submission_file.id,
                assignment_id: @assignment.id,
                result_id: @result.id}
      assert_response :success
      assert render_template 'destroy'
    end # End context :destroy

    should 'on :update_annotation' do
      anno = TextAnnotation.make({
        line_start: 1, line_end: 1,
        annotation_text_id: @annotation_text.id,
        submission_file_id:  @submission_file.id})
      put_as @user, :update_annotation,
             format: :js,
             assignment_id: @assignment.id,
             submission_file_id: @submission_file.id,
             result_id: @result.id,
             annotation_text: { id: @annotation_text.id,
                                content: @annotation_text.content}
      assert_response :success
      assert render_template 'update_annotation'
    end # End context :update_annotation
  end # End context TA POST

  context 'An authenticated and authorized Student doing a POST' do
   # A student should get a 404 even if they do everything right
     setup do
      @user = Student.make
      @assignment = Assignment.make
      @text_annotation = TextAnnotation.make({creator: @user})
      @category = AnnotationCategory.make
      @annotation_text = AnnotationText.make
      @submission_file = SubmissionFile.make
      @result = Result.make
    end

    should 'on :add_existing_annotation' do
      post_as @user, :add_existing_annotation, {
        annotation_text_id: @annotation_text.id,
        submission_file_id: @submission_file.id,
        assignment_id: @assignment.id,
        result_id: @result.id,
        line_start: 1, line_end: 1}
      assert_response :not_found
    end # End context :add_existing_annotation

    should 'on :create to make a text annotation' do
      post_as @user, :create, {content: @annotation_text.content,
        category_id: @category.id,
        submission_file_id: @submission_file.id,
        line_start: 1, line_end: 1, annotation_type: 'text',
        result_id: @result.id,
        assignment_id: @assignment.id}
      assert_response :not_found
    end # End context :create

    should 'on :create to make an image annotation' do
      post_as @user, :create, {content: @annotation_text.content,
        category_id: @category.id,
        submission_file_id: @submission_file.id,
        coords: '0,0,1,1', annotation_type: 'image',
        result_id: @result.id,
        assignment_id: @assignment.id}
      assert_response :not_found
    end # End context :create

    should 'on :destroy' do
      delete_as @user,
                :destroy,
                id: 67,
                submission_file_id: @submission_file.id,
                assignment_id: @assignment.id,
                result_id: @result.id
      assert_response :not_found
    end # End context :destroy

    should 'on :update_annotation' do
      anno = Annotation.create({
        line_start: 1, line_end: 1,
        annotation_text_id: @annotation_text.id,
        submission_file_id:  @submission_file.id})
      post_as @user, :update_annotation,  assignment_id: @assignment.id,
              result_id: @result.id,
              annotation_text: { id: @annotation_text.id,
                                 content: @annotation_text.content,
                                 submission_file_id:@submission_file.id }
      assert_response :not_found
    end # End context :update_annotation
  end # End context Student POST

  should 'recognize action to update_annotation' do
    assert_recognizes(
      { action: 'update_annotation', controller: 'annotations' },
      path: 'annotations/update_annotation',
      method: 'patch')
  end

  should 'recognize action to destroy' do
    assert_recognizes({ action: 'destroy', controller: 'annotations', id: '1' },
                      path: 'annotations/1', method: 'delete')
  end
end
