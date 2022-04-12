describe Api::RolesController do
  let(:course) { create :course }
  let(:instructor) { create :instructor, course: course }
  context 'An unauthenticated request' do
    before :each do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it 'should fail to authenticate a GET index request' do
      get :index, params: { course_id: course.id }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a GET show request' do
      get :show, params: { id: instructor.id, course_id: course.id }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a POST create request' do
      post :create, params: { course_id: course.id }

      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a PUT update request' do
      put :update, params: { id: instructor.id, course_id: course.id }
      expect(response).to have_http_status(403)
    end
  end
  context 'An authenticated request' do
    let(:students) { create_list :student, 3, course: course }
    before :each do
      instructor.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{instructor.api_key.strip}"
    end
    context 'GET index' do
      context 'for a different course' do
        it 'should return a 403 error' do
          get :index, params: { course_id: create(:course).id }
          expect(response.status).to eq(403)
        end
      end
      context 'for a non-existant course' do
        it 'should return a 404 error' do
          get :index, params: { course_id: Course.ids.max + 1 }
          expect(response.status).to eq(404)
        end
      end
      context 'expecting an xml response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/xml'
          students
        end
        it 'should be successful' do
          get :index, params: { course_id: course.id }
          expect(response.status).to eq(200)
        end
        it 'should return info about all the users' do
          get :index, params: { course_id: course.id }
          user_names = Hash.from_xml(response.body).dig('roles', 'role').map { |h| h['user_name'] }
          expect(user_names).to contain_exactly(*User.all.pluck(:user_name))
        end
        it 'should return info about a single user if a filter is used' do
          get :index, params: { filter: { user_name: students[0].user_name }, course_id: course.id }
          user_names = Hash.from_xml(response.body).dig('roles', 'role')['user_name']
          expect(user_names).to eq(students[0].user_name)
        end
        it 'should return all information in the default fields' do
          get :index, params: { course_id: course.id }
          info = Hash.from_xml(response.body).dig('roles', 'role')[0]
          expect(Set.new(info.keys.map(&:to_sym))).to eq Set.new(Api::RolesController::DEFAULT_FIELDS)
        end
      end
      context 'expecting an json response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/json'
          students
        end
        it 'should be successful' do
          get :index, params: { course_id: course.id }
          expect(response.status).to eq(200)
        end
        it 'should return info about all the users' do
          get :index, params: { course_id: course.id }
          expect(JSON.parse(response.body).map { |h| h['user_name'] }).to contain_exactly(*User.all.pluck(:user_name))
        end
        it 'should return info about a single user if a filter is used' do
          get :index, params: { filter: { user_name: students[0].user_name }, course_id: course.id }
          expect(JSON.parse(response.body).map { |h| h['user_name'] }).to eq([students[0].user_name])
        end
        it 'should return all information in the default fields' do
          get :index, params: { course_id: course.id }
          info = JSON.parse(response.body)[0]
          expect(Set.new(info.keys.map(&:to_sym))).to eq Set.new(Api::RolesController::DEFAULT_FIELDS)
        end
      end
    end
    context 'GET show' do
      context 'for a different course' do
        let(:student) { create :student, course: create(:course) }
        it 'should return a 403 error' do
          get :index, params: { course_id: student.course_id }
          expect(response.status).to eq(403)
        end
      end
      context 'for a non-existant course' do
        it 'should return a 404 error' do
          get :index, params: { id: students[0].id, course_id: Course.ids.max + 1 }
          expect(response.status).to eq(404)
        end
      end
      context 'expecting an xml response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/xml'
          students
        end
        it 'should be successful' do
          get :show, params: { id: students[0].id, course_id: course.id }
          expect(response.status).to eq(200)
        end
        it 'should return info about the user' do
          get :show, params: { id: students[0].id, course_id: course.id }
          expect(Hash.from_xml(response.body)['role']['user_name']).to eq(students[0].user_name)
        end
        it 'should return all information in the default fields' do
          get :show, params: { id: students[0].id, course_id: course.id }
          info = Hash.from_xml(response.body)['role']
          expect(Set.new(info.keys.map(&:to_sym))).to eq Set.new(Api::RolesController::DEFAULT_FIELDS)
        end
      end
      context 'expecting an json response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/json'
        end
        it 'should be successful' do
          get :show, params: { id: students[0].id, course_id: course.id }
          expect(response.status).to eq(200)
        end
        it 'should return info about the user' do
          get :show, params: { id: students[0].id, course_id: course.id }
          expect(JSON.parse(response.body)['user_name']).to eq(students[0].user_name)
        end
        it 'should return all information in the default fields' do
          get :show, params: { id: students[0].id, course_id: course.id }
          info = JSON.parse(response.body)
          expect(Set.new(info.keys.map(&:to_sym))).to eq Set.new(Api::RolesController::DEFAULT_FIELDS)
        end
      end
    end
    shared_examples 'creating' do |method|
      let(:end_user) { create :end_user }
      let(:student) { build :student, user: end_user, course: course }
      let(:user_name) { student.user_name }
      let(:type) { student.type }
      let(:first_name) { student.first_name }
      let(:last_name) { student.last_name }
      context 'for a different course' do
        it 'should return a 403 error' do
          post method, params: { user_name: user_name, type: type, course_id: create(:course).id }
          expect(response.status).to eq(403)
        end
      end
      context 'for a non-existant course' do
        it 'should return a 404 error' do
          post method, params: { user_name: user_name, type: type, course_id: Course.ids.max + 1 }
          expect(response.status).to eq(404)
        end
      end
      context 'for the same course' do
        let(:other_params) { {} }
        before :each do
          post method, params: { user_name: user_name, type: type, course_id: course.id, **other_params }
        end
        context 'when creating a new user' do
          let(:created_student) { Student.joins(:user).where('users.user_name': student.user_name).first }
          it 'should be successful' do
            expect(response.status).to eq(201)
          end
          it 'should create a new user' do
            expect(created_student).not_to be_nil
          end
          context 'with other params' do
            let(:section) { create :section }
            let(:other_params) { { section_name: section.name, grace_credits: 5, hidden: true } }
            it 'should set the section' do
              expect(created_student.section.id).to eq section.id
            end
            it 'should set the grace credits' do
              expect(created_student.grace_credits).to eq 5
            end
            it 'should set the hidden value' do
              expect(created_student.hidden).to eq true
            end
          end
        end
        context 'when creating a student with an invalid user_name' do
          let(:user_name) { 'a!!' }
          it 'should raise a 422 error' do
            expect(response.status).to eq(422)
          end
        end
        context 'when creating a student with an invalid type' do
          let(:type) { 'Dragon' }
          it 'should raise a 422 error' do
            expect(response.status).to eq(422)
          end
        end
      end
    end
    context 'PUT create_or_unhide' do
      it_behaves_like 'creating', :create_or_unhide
      context 'when trying to create a user who already exists' do
        it 'should unhide the user' do
          student = create :student, course: course, hidden: true
          post :create_or_unhide, params: { user_name: student.user_name, type: :student, course_id: course.id }
          expect(student.reload.hidden).to be false
        end
      end
    end
    context 'POST create' do
      it_behaves_like 'creating', :create
      context 'when trying to create a user who already exists' do
        it 'should raise a 422 error' do
          student = create :student, course: course
          post :create, params: { user_name: student.user_name, type: :student, course_id: course.id }
          expect(response.status).to eq(422)
        end
      end
    end
    context 'PUT update' do
      let(:student) { create :student, course: course, hidden: false }
      let(:tmp_student) { build :student, course: course }
      context 'for a different course' do
        let(:student) { create :student, course: create(:course) }
        it 'should return a 403 error' do
          put :update, params: { id: student.id, course_id: student.course_id }
          expect(response.status).to eq(403)
        end
      end
      context 'for a non-existant course' do
        it 'should return a 404 error' do
          put :update, params: { id: student.id, course_id: Course.ids.max + 1 }
          expect(response.status).to eq(404)
        end
      end
      context 'when updating an existing user' do
        it 'should not update a user name' do
          put :update, params: { id: student.id, user_name: tmp_student.user_name, course_id: course.id }
          expect(response.status).to eq(200)
          student.reload
          expect(student.user_name).not_to eq(tmp_student.user_name)
        end
        it 'should not update a first name' do
          put :update, params: { id: student.id, first_name: tmp_student.first_name, course_id: course.id }
          expect(response.status).to eq(200)
          student.reload
          expect(student.first_name).not_to eq(tmp_student.first_name)
        end
        it 'should not update a last name' do
          put :update, params: { id: student.id, last_name: tmp_student.last_name, course_id: course.id }
          expect(response.status).to eq(200)
          student.reload
          expect(student.last_name).not_to eq(tmp_student.last_name)
        end
        it 'should update a section' do
          section = create :section
          put :update, params: { id: student.id, section_name: section.name, course_id: course.id }
          expect(response.status).to eq(200)
          student.reload
          expect(student.section.id).to eq(section.id)
        end
        it 'should update grace credits' do
          old_credits = student.grace_credits
          put :update, params: { id: student.id, grace_credits: old_credits + 1, course_id: course.id }
          expect(response.status).to eq(200)
          student.reload
          expect(student.grace_credits).to eq(old_credits + 1)
        end
        it 'should update hidden' do
          put :update, params: { id: student.id, hidden: true, course_id: course.id }
          expect(response.status).to eq(200)
          student.reload
          expect(student.hidden).to eq(true)
        end
      end
      context 'when updating a user that does not exist' do
        it 'should raise a 404 error' do
          put :update, params: { id: student.id + 1, user_name: tmp_student.user_name, course_id: course.id }
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
