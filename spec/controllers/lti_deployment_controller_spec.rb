describe LtiDeploymentController do
  let(:instructor) { create :instructor }
  let(:target_link_uri) { 'https://example.com/authorize_redirect' }

  describe '#choose_course', :choose_course do
    let!(:course) { create :course }
    let(:instructor) { create :instructor, course: course }
    let!(:lti) { create :lti_deployment }

    before :each do
      session[:lti_deployment_id] = lti.id
    end
    context 'when picking a course' do
      it 'redirects to a course on success' do
        post_as instructor, :choose_course, params: { course: course.id }
        expect(response).to redirect_to course_path(course)
      end
      it 'updates the course on the lti object' do
        post_as instructor, :choose_course, params: { course: course.id }
        lti.reload
        expect(lti.course).to eq(course)
      end
      context 'when the user does not have permission to link' do
        let(:course2) { create :course }
        let(:instructor2) { create :instructor, course: course2 }
        it 'does not allow users to link courses they are not instructors for' do
          post_as instructor2, :choose_course, params: { course: course.id }
          expect(flash[:error]).not_to be_empty
        end
      end
    end
  end
  describe '#new_course' do
    let(:lti_deployment) { create :lti_deployment }
    let(:course_params) { { display_name: 'Introduction to Computer Science', name: 'csc108' } }
    before :each do
      session[:lti_deployment_id] = lti_deployment.id
      post_as instructor, :create_course, params: course_params
    end
    it 'creates a course' do
      expect(Course.find_by(name: 'csc108')).not_to be_nil
    end
    it 'sets the course display name' do
      expect(Course.find_by(display_name: 'Introduction to Computer Science')).not_to be_nil
    end
    it 'creates an instructor role for the user' do
      expect(Role.find_by(user: instructor.user, course: Course.find_by(name: 'csc108'))).not_to be_nil
    end
  end
end
