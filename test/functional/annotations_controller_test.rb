require File.dirname(__FILE__) + '/authenticated_controller_test'
require 'shoulda'
require 'machinist'


class AnnotationsControllerTest < AuthenticatedControllerTest

  def setup
    clear_fixtures
  end

  context "An unauthenticated and unauthorized user doing a GET" do

    # Since we are not authenticated and authorized, we should be redirected
    # to the login page

    context "on :add_existing_annotation" do
      setup do
        get :add_existing_annotation, :id => 1
      end
      should respond_with :redirect
    end

    context "on :create" do
      setup do
        get :create, :id => 1
      end
      should respond_with :redirect
    end

    context "on :destroy" do
      setup do
        get :destroy, :id => 1
      end
      should respond_with :redirect
    end

    context "on :update_annotation" do
      setup do
        get :update_annotation, :id => 1
      end
      should respond_with :redirect
    end

    context "on :update_comment" do
      setup do
        get :update_comment, :id => 1
      end
      should respond_with :redirect
    end

  end # end context unauthenticated/unauthorized user GET

  context "An unauthenticated and unauthorized user doing a POST" do

    # Since we are not authenticated and authorized, we should be redirected
    # to the login page

    context "on :add_existing_annotation" do
      setup do
        post :add_existing_annotation, :id => 1
      end
      should respond_with :redirect
    end

    context "on :create" do
      setup do
        post :create, :id => 1
      end
      should respond_with :redirect
    end

    context "on :destroy" do
      setup do
        post :destroy, :id => 1
      end
      should respond_with :redirect
    end

    context "on :update_annotation" do
      setup do
        post :update_annotation, :id => 1
      end
      should respond_with :redirect
    end

    context "on :update_comment" do
      setup do
        post :update_comment, :id => 1
      end
      should respond_with :redirect
    end

  end # end context unauthenticated/unauthorized user POST

  context "An authenticated and authorized admin doing a POST" do
     setup do
      @user = Admin.make()
      @assignment = Assignment.make()
      @text_annotation = TextAnnotation.make()
      @category = AnnotationCategory.make()
      @annotation_text = AnnotationText.make()
      @submission_file = SubmissionFile.make()
      @result = Submission.make.result
    end

    context "on :add_existing_annotation" do
      setup do
        post_as @user, :add_existing_annotation, {
          :annotation_text_id => @annotation_text.id,
          :submission_file_id => @submission_file.id,
          :line_start => 1, :line_end => 1}
      end
      should respond_with :success
      should assign_to :submission_file
      should assign_to :annotation
      should render_template 'add_existing_annotation'
    end # End context :add_existing_annotation

    context "on :create to make a text annotation" do
      setup do
        post_as @user, :create, {:content => @annotation_text.content,
          :category_id => @category.id,
          :submission_file_id => @submission_file.id,
          :line_start => 1, :line_end => 1, :annotation_type => 'text'}
      end
      should respond_with :success
      should assign_to :submission_file
      should assign_to :annotation
      should render_template 'create'
    end # End context :create text

    context "on :create to make an image annotation" do
      setup do
        post_as @user, :create, {:content => @annotation_text.content,
          :category_id => @category.id,
          :submission_file_id => @submission_file.id,
          :coords => "0,0,1,1", :annotation_type => 'image'}
      end
      should respond_with :success
      should assign_to :submission_file
      should assign_to :annotation
      should render_template 'create'
    end # End context :create image

    context "on :destroy" do
      setup do
         anno = TextAnnotation.create({
        :line_start => 1, :line_end => 1,
        :annotation_text_id => @annotation_text.id,
        :submission_file_id =>  @submission_file.id,
        :annotation_number => 1})
        post_as @user, :destroy, {:id => anno.id,
          :submission_file_id => @submission_file.id}
      end
      should respond_with :success
      should render_template 'destroy'
    end # End context :destroy

    context "on :update_annotation" do
      setup do
         anno = TextAnnotation.create({
        :line_start => 1, :line_end => 1,
        :annotation_text_id => @annotation_text.id,
        :submission_file_id =>  @submission_file.id})
        post_as @user, :update_annotation, :annotation_text => {
          :id => @annotation_text.id, :content => @annotation_text.content,
          :submission_file_id =>@submission_file.id}
      end
      should respond_with :success
      should render_template 'update_annotation'
    end # End context :update_annotation

    context "on :update_comment" do
      setup do
         post_as @user, :update_comment, {:result_id => @result.id,
           :overall_comment => "comment"}
      end
      should respond_with :success
    end # End context :update_comment
  end #End context admin POST

  context "An authenticated and authorized TA doing a POST" do
     setup do
      @user = Ta.make()
      @assignment = Assignment.make()
      @text_annotation = TextAnnotation.make()
      @category = AnnotationCategory.make()
      @annotation_text = AnnotationText.make()
      @submission_file = SubmissionFile.make()
      @result = Submission.make.result
     end

    context "on :add_existing_annotation" do
      setup do
        post_as @user, :add_existing_annotation, {
          :annotation_text_id => @annotation_text.id,
          :submission_file_id => @submission_file.id,
          :line_start => 1, :line_end => 1}
      end
      should respond_with :success
      should assign_to :submission_file
      should assign_to :annotation
      should render_template 'add_existing_annotation'
    end # End context :add_existing_annotation

    context "on :create to make a text annotation" do
      setup do
        post_as @user, :create, {:content => @annotation_text.content,
          :category_id => @category.id,
          :submission_file_id => @submission_file.id,
          :line_start => 1, :line_end => 1, :annotation_type => 'text'}
      end
      should respond_with :success
      should assign_to :submission_file
      should assign_to :annotation
      should render_template 'create'
    end # End context :create text

    context "on :create to make an image annotation" do
      setup do
        post_as @user, :create, {:content => @annotation_text.content,
          :category_id => @category.id,
          :submission_file_id => @submission_file.id,
          :coords => "0,0,1,1", :annotation_type => 'image'}
      end
      should respond_with :success
      should assign_to :submission_file
      should assign_to :annotation
      should render_template 'create'
    end # End context :create image

    context "on :destroy" do
      setup do
         anno = TextAnnotation.create({
        :line_start => 1, :line_end => 1,
        :annotation_text_id => @annotation_text.id,
        :submission_file_id =>  @submission_file.id,
        :annotation_number => 1})
        post_as @user, :destroy, {:id => anno.id,
          :submission_file_id => @submission_file.id}
      end
      should respond_with :success
      should render_template 'destroy'
    end # End context :destroy

    context "on :update_annotation" do
      setup do
         anno = TextAnnotation.create({
        :line_start => 1, :line_end => 1,
        :annotation_text_id => @annotation_text.id,
        :submission_file_id =>  @submission_file.id})
        post_as @user, :update_annotation, :annotation_text => {
          :id => @annotation_text.id, :content => @annotation_text.content,
          :submission_file_id =>@submission_file.id}
      end
      should respond_with :success
      should render_template 'update_annotation'
    end # End context :update_annotation

    context "on :update_comment" do
      setup do
         post_as @user, :update_comment, {:result_id => @result.id,
           :overall_comment => "comment"}
      end
      should respond_with :success
    end # End context :update_comment
  end # End context TA POST

  context "An authenticated and authorized Student doing a POST" do
   # A student should get a 404 even if they do everything right
     setup do
      @user = Student.make()
      @assignment = Assignment.make()
      @text_annotation = TextAnnotation.make()
      @category = AnnotationCategory.make()
      @annotation_text = AnnotationText.make()
      @submission_file = SubmissionFile.make()
      @result = Submission.make.result
    end
    context "on :add_existing_annotation" do
      setup do
        post_as @user, :add_existing_annotation, {
          :annotation_text_id => @annotation_text.id,
          :submission_file_id => @submission_file.id,
          :line_start => 1, :line_end => 1}
      end
      should respond_with :not_found
    end # End context :add_existing_annotation

    context "on :create to make a text annotation" do
      setup do
        post_as @user, :create, {:content => @annotation_text.content,
          :category_id => @category.id,
          :submission_file_id => @submission_file.id,
          :line_start => 1, :line_end => 1, :annotation_type => 'text'}
      end
      should respond_with :not_found
    end # End context :create

    context "on :create to make an image annotation" do
      setup do
        post_as @user, :create, {:content => @annotation_text.content,
          :category_id => @category.id,
          :submission_file_id => @submission_file.id,
          :coords => "0,0,1,1", :annotation_type => 'image'}
      end
      should respond_with :not_found
    end # End context :create

    context "on :destroy" do
      setup do
         anno = Annotation.create({
        :line_start => 1, :line_end => 1,
        :annotation_text_id => @annotation_text.id,
        :submission_file_id =>  @submission_file.id,
        :annotation_number => 1})
        post_as @user, :destroy, {:id => anno.id,
          :submission_file_id => @submission_file.id}
      end
      should respond_with :not_found
    end # End context :destroy

    context "on :update_annotation" do
      setup do
         anno = Annotation.create({
        :line_start => 1, :line_end => 1,
        :annotation_text_id => @annotation_text.id,
        :submission_file_id =>  @submission_file.id})
        post_as @user, :update_annotation, :annotation_text => {
          :id => @annotation_text.id, :content => @annotation_text.content,
          :submission_file_id =>@submission_file.id}
      end
      should respond_with :not_found
    end # End context :update_annotation

    context "on :update_comment" do
      setup do
         post_as @user, :update_comment, {:result_id => @result.id,
           :overall_comment => "comment"}
      end
      should respond_with :not_found
    end # End context :update_comment
  end # End context Student POST
end
