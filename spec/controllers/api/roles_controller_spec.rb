describe Api::RolesController do
  let(:course) { create(:course) }
  let(:instructor) { create(:instructor, course: course) }

  context 'An unauthenticated request' do
    before do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it 'should fail to authenticate a GET index request' do
      get :index, params: { course_id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a GET show request' do
      get :show, params: { id: instructor.id, course_id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a POST create request' do
      post :create, params: { course_id: course.id }

      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a PUT update request' do
      put :update, params: { id: instructor.id, course_id: course.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'An authenticated request' do
    let!(:admin) { create(:admin_role, course: course) }
    let(:students) { create_list(:student, 3, course: course) }

    shared_examples 'get all users' do
      context 'for a non-existent course' do
        it 'should return a 404 error' do
          get :index, params: { course_id: Course.ids.max + 1 }
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'expecting an xml response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/xml'
          students
        end

        it 'should be successful' do
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(:ok)
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
        before do
          request.env['HTTP_ACCEPT'] = 'application/json'
          students
        end

        it 'should be successful' do
          get :index, params: { course_id: course.id }
          expect(response).to have_http_status(:ok)
        end

        it 'should return info about a single user if a filter is used' do
          get :index, params: { filter: { user_name: students[0].user_name }, course_id: course.id }
          expect(response.parsed_body.pluck('user_name')).to eq([students[0].user_name])
        end

        it 'should return all information in the default fields' do
          get :index, params: { course_id: course.id }
          info = response.parsed_body[0]
          expect(Set.new(info.keys.map(&:to_sym))).to eq Set.new(Api::RolesController::DEFAULT_FIELDS)
        end
      end
    end

    shared_examples 'finding a user' do
      context 'for a non-existant course' do
        it 'should return a 404 error' do
          get :show, params: { id: students[0].id, course_id: Course.ids.max + 1 }
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'expecting an xml response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/xml'
          students
        end

        it 'should be successful' do
          get :show, params: { id: students[0].id, course_id: course.id }
          expect(response).to have_http_status(:ok)
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
        before do
          request.env['HTTP_ACCEPT'] = 'application/json'
        end

        it 'should be successful' do
          get :show, params: { id: students[0].id, course_id: course.id }
          expect(response).to have_http_status(:ok)
        end

        it 'should return info about the user' do
          get :show, params: { id: students[0].id, course_id: course.id }
          expect(response.parsed_body['user_name']).to eq(students[0].user_name)
        end

        it 'should return all information in the default fields' do
          get :show, params: { id: students[0].id, course_id: course.id }
          info = response.parsed_body
          expect(Set.new(info.keys.map(&:to_sym))).to eq Set.new(Api::RolesController::DEFAULT_FIELDS)
        end
      end
    end

    shared_examples 'creating' do |method|
      let(:end_user) { create(:end_user) }
      let(:student) { build(:student, user: end_user, course: course) }
      let(:user_name) { student.user_name }
      let(:type) { student.type }
      let(:first_name) { student.first_name }
      let(:last_name) { student.last_name }

      context 'for a non-existant course' do
        it 'should return a 404 error' do
          post method, params: { user_name: user_name, type: type, course_id: Course.ids.max + 1 }
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'for the same course' do
        let(:other_params) { {} }

        before do
          post method, params: { user_name: user_name, type: type, course_id: course.id, **other_params }
        end

        context 'when creating a new student' do
          let(:created_student) { Student.joins(:user).where('users.user_name': student.user_name).first }

          it 'should be successful' do
            expect(response).to have_http_status(:created)
          end

          it 'should create a new user' do
            expect(created_student).not_to be_nil
          end

          context 'with other params' do
            let(:section) { create(:section) }
            let(:other_params) { { section_name: section.name, grace_credits: 5, hidden: true } }

            it 'should set the section' do
              expect(created_student.section.id).to eq section.id
            end

            it 'should set the grace credits' do
              expect(created_student.grace_credits).to eq 5
            end

            it 'should set the hidden value' do
              expect(created_student.hidden).to be true
            end
          end
        end

        context 'when creating a student with an invalid user_name' do
          let(:user_name) { 'a!!' }

          it 'should raise a 422 error' do
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context 'when creating a student with an invalid type' do
          let(:type) { 'Dragon' }

          it 'should raise a 422 error' do
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context 'with an invalid section name' do
          let(:other_params) { { section_name: 'section.name' } }

          it 'should raise a 422 error' do
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context 'with a nil section name' do
          let(:created_student) { Student.joins(:user).where('users.user_name': student.user_name).first }
          let(:other_params) { { section_name: nil } }

          it 'should be successful' do
            expect(response).to have_http_status(:created)
          end

          it 'should not set a section' do
            expect(created_student.section).to be_nil
          end
        end
      end
    end

    shared_examples 'updating' do
      let(:student) { create(:student, course: course, hidden: false) }
      let(:tmp_student) { build(:student, course: course) }

      context 'for a non-existant course' do
        it 'should return a 404 error' do
          put :update, params: { id: student.id, course_id: Course.ids.max + 1 }
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when updating an existing user' do
        it 'should not update a user name' do
          put :update, params: { id: student.id, user_name: tmp_student.user_name, course_id: course.id }
          expect(response).to have_http_status(:ok)
          student.reload
          expect(student.user_name).not_to eq(tmp_student.user_name)
        end

        it 'should not update a first name' do
          new_name = student.first_name + 'a'
          put :update, params: { id: student.id, first_name: new_name, course_id: course.id }
          expect(response).to have_http_status(:ok)
          student.reload
          expect(student.first_name).not_to eq(new_name)
        end

        it 'should not update a last name' do
          new_name = student.last_name + 'a'
          put :update, params: { id: student.id, last_name: new_name, course_id: course.id }
          expect(response).to have_http_status(:ok)
          student.reload
          expect(student.last_name).not_to eq(new_name)
        end

        it 'should update a section' do
          section = create(:section)
          put :update, params: { id: student.id, section_name: section.name, course_id: course.id }
          expect(response).to have_http_status(:ok)
          student.reload
          expect(student.section.id).to eq(section.id)
        end

        it 'should update grace credits' do
          old_credits = student.grace_credits
          put :update, params: { id: student.id, grace_credits: old_credits + 1, course_id: course.id }
          expect(response).to have_http_status(:ok)
          student.reload
          expect(student.grace_credits).to eq(old_credits + 1)
        end

        it 'should update hidden' do
          put :update, params: { id: student.id, hidden: true, course_id: course.id }
          expect(response).to have_http_status(:ok)
          student.reload
          expect(student.hidden).to be(true)
        end

        context 'with an invalid section name' do
          it 'should raise a 422 error' do
            put :update, params: { id: student.id, course_id: course.id, section_name: 'section.name' }
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context 'with a nil section name' do
          let(:section) { create(:section) }

          before do
            student.update!(section: section)
          end

          it 'should be successful' do
            put :update, params: { id: student.id, course_id: course.id, section_name: nil }
            expect(response).to have_http_status(:ok)
          end

          it 'should set the section to nil' do
            put :update, params: { id: student.id, course_id: course.id, section_name: nil }
            student.reload
            expect(student.section).to be_nil
          end
        end
      end

      context 'when updating a user that does not exist' do
        it 'should raise a 404 error' do
          put :update, params: { id: student.id + 1, user_name: tmp_student.user_name, course_id: course.id }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'As an instructor' do
      before do
        instructor.reset_api_key
        request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{instructor.api_key.strip}"
      end

      context 'GET index' do
        it_behaves_like 'get all users'

        context 'for a different course' do
          it 'should return a 403 error' do
            get :index, params: { course_id: create(:course).id }
            expect(response).to have_http_status(:forbidden)
          end
        end

        it 'xml response returns info about all users except admins' do
          students
          request.env['HTTP_ACCEPT'] = 'application/xml'
          get :index, params: { course_id: course.id }
          user_names = Hash.from_xml(response.body).dig('roles', 'role').pluck('user_name')
          expect(user_names).to match_array(User.where.not(type: AdminUser.name).pluck(:user_name))
        end

        it 'json response returns info about all users except admins' do
          students
          request.env['HTTP_ACCEPT'] = 'application/json'
          get :index, params: { course_id: course.id }
          expect(response.parsed_body.pluck('user_name')).to match_array(User.where
                 .not(type: AdminUser.name)
                 .pluck(:user_name))
        end
      end

      context 'GET show' do
        it_behaves_like 'finding a user'

        context 'for a different course' do
          let(:student) { create(:student, course: create(:course)) }

          it 'should return a 403 error' do
            get :show, params: { id: student.id, course_id: student.course_id }
            expect(response).to have_http_status(:forbidden)
          end
        end

        context 'an admin' do
          it 'xml response is not successful' do
            get :show, format: 'xml', params: { id: admin.id, course_id: course.id }
            expect(response).to have_http_status(:forbidden)
          end

          it 'json response is not successful' do
            get :show, format: 'json', params: { id: admin.id, course_id: course.id }
            expect(response).to have_http_status(:forbidden)
          end
        end
      end

      context 'PUT create_or_unhide' do
        it_behaves_like 'creating', :create_or_unhide
        context 'for a different course' do
          it 'should return a 403 error' do
            student = build(:student, course: course)
            post :create_or_unhide, params: { user_name: student.user_name,
                                              type: student.type,
                                              course_id: create(:course).id }
            expect(response).to have_http_status(:forbidden)
          end
        end

        context 'when trying to create a user who already exists' do
          it 'should unhide the user' do
            student = create(:student, course: course, hidden: true)
            post :create_or_unhide, params: { user_name: student.user_name, type: :student, course_id: course.id }
            expect(student.reload.hidden).to be false
          end
        end

        context 'when trying to create an admin who already exists' do
          it 'returns a 403 error' do
            admin = create(:admin_role, course: course, hidden: true)
            post :create_or_unhide, params: { user_name: admin.user_name, type: :admin_role, course_id: course.id }
            expect(response).to have_http_status(:forbidden)
          end

          it 'does not unhide the admin' do
            admin = create(:admin_role, course: course, hidden: true)
            post :create_or_unhide, params: { user_name: admin.user_name, type: :admin_role, course_id: course.id }
            expect(admin.reload.hidden).to be true
          end
        end

        context 'when trying to create a new admin' do
          it 'returns a 403 error' do
            admin_user = create(:admin_user)
            post :create_or_unhide, params: { user_name: admin_user.user_name,
                                              last_name: admin_user.last_name,
                                              first_name: admin_user.first_name,
                                              type: AdminRole.name,
                                              course_id: course.id }
            expect(response).to have_http_status(:forbidden)
          end
        end
      end

      context 'POST create' do
        it_behaves_like 'creating', :create

        context 'for a different course' do
          it 'should return a 403 error' do
            student = build(:student, course: course)
            post :create, params: { user_name: student.user_name,
                                    type: student.type,
                                    course_id: create(:course).id }
            expect(response).to have_http_status(:forbidden)
          end
        end

        context 'when trying to create a user who already exists' do
          it 'should raise a 422 error' do
            student = create(:student, course: course)
            post :create, params: { user_name: student.user_name, type: :student, course_id: course.id }
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context 'when trying to create a new admin' do
          it 'returns a 403 error' do
            admin_user = create(:admin_user)
            post :create, params: { user_name: admin_user.user_name,
                                    last_name: admin_user.last_name,
                                    first_name: admin_user.first_name,
                                    type: AdminRole.name,
                                    course_id: course.id }
            expect(response).to have_http_status(:forbidden)
          end
        end
      end

      context 'PUT update' do
        it_behaves_like 'updating'

        context 'for a different course' do
          let(:student) { create(:student, course: create(:course)) }

          it 'should return a 403 error' do
            put :update, params: { id: student.id, course_id: student.course_id }
            expect(response).to have_http_status(:forbidden)
          end
        end

        context 'updating an admin' do
          let(:admin) { create(:admin_role, hidden: false, course: course) }

          it 'returns a 403 error' do
            put :update, params: { id: admin.id, hidden: true, course_id: course.id }
            expect(response).to have_http_status(:forbidden)
          end

          it 'does not update the admin' do
            put :update, params: { id: admin.id, hidden: true, course_id: course.id }
            admin.reload
            expect(admin.hidden).to be(false)
          end
        end
      end
    end

    context 'As an admin' do
      before do
        admin.reset_api_key
        request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{admin.api_key.strip}"
      end

      context 'GET index' do
        it_behaves_like 'get all users'

        it 'xml response returns info about all users' do
          students
          request.env['HTTP_ACCEPT'] = 'application/xml'
          get :index, params: { course_id: course.id }
          user_names = Hash.from_xml(response.body).dig('roles', 'role').pluck('user_name')
          expect(user_names).to match_array(User.pluck(:user_name))
        end

        it 'json response returns info about all users' do
          students
          request.env['HTTP_ACCEPT'] = 'application/json'
          get :index, params: { course_id: course.id }
          expect(response.parsed_body.pluck('user_name')).to match_array(User.pluck(:user_name))
        end
      end

      context 'GET show' do
        it_behaves_like 'finding a user'

        context 'an admin' do
          it 'xml response is successful' do
            get :show, format: 'xml', params: { id: admin.id, course_id: course.id }
            expect(response).to have_http_status(:ok)
          end

          it 'json response is successful' do
            get :show, format: 'json', params: { id: admin.id, course_id: course.id }
            expect(response).to have_http_status(:ok)
          end
        end
      end

      context 'PUT create_or_unhide' do
        it_behaves_like 'creating', :create_or_unhide

        context 'when trying to create a user who already exists' do
          it 'should unhide the user' do
            student = create(:student, course: course, hidden: true)
            post :create_or_unhide, params: { user_name: student.user_name, type: :student, course_id: course.id }
            expect(student.reload.hidden).to be false
          end
        end

        context 'when trying to create an admin who already exists' do
          it 'is successful' do
            admin = create(:admin_role, course: course, hidden: true)
            post :create_or_unhide, params: { user_name: admin.user_name, type: :admin_role, course_id: course.id }
            expect(response).to have_http_status(:ok)
          end

          it 'unhides the admin' do
            admin = create(:admin_role, course: course, hidden: true)
            post :create_or_unhide, params: { user_name: admin.user_name, type: :admin_role, course_id: course.id }
            expect(admin.reload.hidden).to be false
          end
        end

        context 'when trying to create a new admin' do
          it 'is successful' do
            admin_user = create(:admin_user)
            post :create_or_unhide, params: { user_name: admin_user.user_name,
                                              last_name: admin_user.last_name,
                                              first_name: admin_user.first_name,
                                              type: AdminRole.name,
                                              course_id: course.id }
            expect(response).to have_http_status(:created)
          end

          it 'creates a new admin role' do
            admin_user = create(:admin_user)
            post :create_or_unhide, params: { user_name: admin_user.user_name,
                                              last_name: admin_user.last_name,
                                              first_name: admin_user.first_name,
                                              type: AdminRole.name,
                                              course_id: course.id }
            admin_role = Role.find_by(user: admin_user, course: course)
            expect(admin_role).not_to be_nil
          end
        end
      end

      context 'POST create' do
        it_behaves_like 'creating', :create

        context 'when trying to create a user who already exists' do
          it 'should raise a 422 error' do
            student = create(:student, course: course)
            post :create, params: { user_name: student.user_name, type: :student, course_id: course.id }
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context 'when trying to create a new admin' do
          it 'is successful' do
            admin_user = create(:admin_user)
            post :create, params: { user_name: admin_user.user_name,
                                    last_name: admin_user.last_name,
                                    first_name: admin_user.first_name,
                                    type: AdminRole.name,
                                    course_id: course.id }
            expect(response).to have_http_status(:created)
          end

          it 'creates a new admin role' do
            admin_user = create(:admin_user)
            post :create, params: { user_name: admin_user.user_name,
                                    last_name: admin_user.last_name,
                                    first_name: admin_user.first_name,
                                    type: AdminRole.name,
                                    course_id: course.id }
            admin_role = Role.find_by(user: admin_user, course: course)
            expect(admin_role).not_to be_nil
          end
        end
      end

      context 'PUT update' do
        it_behaves_like 'updating'

        context 'updating an admin' do
          let(:admin) { create(:admin_role, hidden: false, course: course) }

          it 'is successful' do
            put :update, params: { id: admin.id, hidden: true, course_id: course.id }
            expect(response).to have_http_status(:ok)
          end

          it 'updates the admin' do
            put :update, params: { id: admin.id, hidden: true, course_id: course.id }
            admin.reload
            expect(admin.hidden).to be(true)
          end
        end
      end
    end
  end
end
