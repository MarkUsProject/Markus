describe Admin::CoursesController do
  describe '#index' do
    let!(:course1) { create(:course) }
    let!(:course2) { create(:course) }
    let!(:course3) { create(:course) }
    shared_examples 'user with unauthorized access' do
      it 'responds with 403' do
        get_as user, :index, format: 'json'
        expect(response).to have_http_status(403)
      end
    end
    context 'Instructor' do
      let(:user) { create(:instructor) }
      include_examples 'user with unauthorized access'
    end
    context 'TA' do
      let(:user) { create(:ta) }
      include_examples 'user with unauthorized access'
    end
    context 'Student' do
      let(:user) { create(:student) }
      include_examples 'user with unauthorized access'
    end
    context 'Admin' do
      let(:user) { create(:admin_user) }
      context 'when sending html' do
        it 'responds with 200' do
          get_as user, :index, format: 'html'
          expect(response).to have_http_status(200)
        end
      end
      context 'when sending json' do
        it 'responds with 200' do
          get_as user, :index, format: 'json'
          expect(response).to have_http_status(200)
        end
        it 'sends the appropriate data' do
          get_as user, :index, format: 'json'
          received_data = JSON.parse(response.body).map(&:symbolize_keys)
          expected_data = [
            {
              id: course1.id,
              name: course1.name,
              display_name: course1.display_name,
              is_hidden: course1.is_hidden
            },
            {
              id: course2.id,
              name: course2.name,
              display_name: course2.display_name,
              is_hidden: course2.is_hidden
            },
            {
              id: course3.id,
              name: course3.name,
              display_name: course3.display_name,
              is_hidden: course3.is_hidden
            }
          ]
          expect(received_data).to match_array(expected_data)
        end
      end
    end
  end

  describe '#edit' do
    let!(:course) { create(:course) }
    shared_examples 'user with unauthorized access' do
      it 'responds with 403' do
        get_as user, :edit, params: { id: course.id }
        expect(response).to have_http_status(403)
      end
    end
    context 'Instructor' do
      let(:user) { create(:instructor) }
      include_examples 'user with unauthorized access'
    end
    context 'TA' do
      let(:user) { create(:ta) }
      include_examples 'user with unauthorized access'
    end
    context 'Student' do
      let(:user) { create(:student) }
      include_examples 'user with unauthorized access'
    end
    context 'Admin' do
      let(:user) { create(:admin_user) }
      it 'responds with 200' do
        get_as user, :edit, params: { id: course.id }
        expect(response).to have_http_status(200)
      end
    end
  end

  describe '#update' do
    let(:course) { create(:course) }
    let(:params) do
      {
        id: course.id,
        course: {
          name: 'CSC104',
          display_name: 'Computational Thinking',
          is_hidden: true
        }
      }
    end
    let(:invalid_params) do
      {
        id: course.id,
        course: {
          name: 'CSC2000',
          display_name: nil,
          is_hidden: nil
        }
      }
    end
    shared_examples 'user with unauthorized access' do
      it 'responds with 403' do
        put_as user, :update, params: params
        expect(response).to have_http_status(403)
      end
    end
    context 'Instructor' do
      let(:user) { create(:instructor) }
      include_examples 'user with unauthorized access'
    end
    context 'TA' do
      let(:user) { create(:ta) }
      include_examples 'user with unauthorized access'
    end
    context 'Student' do
      let(:user) { create(:student) }
      include_examples 'user with unauthorized access'
    end
    context 'Admin' do
      let(:user) { create(:admin_user) }
      it 'responds with 302' do
        put_as user, :update, params: params
        expect(response).to have_http_status(302)
      end
      it 'updates the course' do
        put_as user, :update, params: params
        updated_course = Course.find(course.id)
        expected_course_data = {
          name: 'CSC104',
          display_name: 'Computational Thinking',
          is_hidden: true
        }
        updated_course_data = {
          name: updated_course.name,
          display_name: updated_course.display_name,
          is_hidden: updated_course.is_hidden
        }
        expect(updated_course_data).to eq(expected_course_data)
      end
      it 'does not update when parameters are invalid' do
        expected_course_data = {
          name: course.name,
          display_name: course.display_name,
          is_hidden: course.is_hidden
        }
        put_as user, :update, params: invalid_params
        updated_course = Course.find(course.id)
        updated_course_data = {
          name: updated_course.name,
          display_name: updated_course.display_name,
          is_hidden: updated_course.is_hidden
        }
        expect(updated_course_data).to eq(expected_course_data)
      end
    end
  end
end
