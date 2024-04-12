describe InstructorsController do
  let(:course) { instructor.course }
  let(:instructor) { create(:instructor) }
  let(:role) { instructor }
  let(:end_user) { create(:end_user) }

  context 'An Instructor should' do
    describe '#new' do
      it_behaves_like 'role is from a different course' do
        subject { get_as new_role, :new, params: { course_id: course.id } }
      end
      it 'be able to get :new' do
        get_as instructor, :new, params: { course_id: course.id }
        expect(response).to have_http_status(:ok)
      end
    end

    describe '#index' do
      it_behaves_like 'role is from a different course' do
        subject { get_as new_role, :index, params: { course_id: course.id } }
      end
      it 'respond with success on index' do
        get_as instructor, :index, params: { course_id: course.id }
        expect(response).to have_http_status(:ok)
      end

      it 'retrieves correct data' do
        get_as instructor, :index, format: 'json', params: { course_id: course.id }
        response_data = response.parsed_body['data']
        expected_data = course.instructors.joins(:user).where(type: Instructor.name)
                              .pluck_to_hash(:id, :user_name, :first_name, :last_name, :email, :hidden).as_json
        expect(response_data).to eq(expected_data)
      end

      it 'retrieves correct hidden count' do
        get_as instructor, :index, format: 'json', params: { course_id: course.id }
        response_data = response.parsed_body['counts']
        expected_data = {
          all: 1,
          active: 1,
          inactive: 0
        }.as_json
        expect(response_data).to eq(expected_data)
      end
    end

    describe '#create' do
      it_behaves_like 'role is from a different course' do
        subject do
          post_as new_role, :create,
                  params: { course_id: course.id, role: { end_user: { user_name: end_user.user_name } } }
        end
      end
      it 'be able to create Instructor' do
        post_as instructor,
                :create,
                params: { course_id: course.id, role: { end_user: { user_name: end_user.user_name } } }
        expect(course.instructors.joins(:user).where('users.user_name': end_user.user_name)).to exist
        expect(response).to redirect_to action: 'index'
      end

      context 'when changing the default visibility status' do
        let(:params) do
          {
            course_id: course.id,
            role: { end_user: { user_name: end_user.user_name }, hidden: true }
          }
        end

        context 'as an admin' do
          let(:admin) { create(:admin_user) }

          it 'should change the default visibility status' do
            post_as admin, :create, params: params
            instructor = end_user.roles.first
            expect(instructor.hidden).to be(true)
          end
        end

        context 'as an instructor' do
          it 'should not change the default visibility status' do
            post_as instructor, :create, params: params
            instructor = end_user.roles.first
            expect(instructor.hidden).to be(false)
          end
        end
      end

      context 'when a end_user does not exist' do
        subject do
          post_as instructor, :create,
                  params: { course_id: course.id, role: { end_user: { user_name: end_user.user_name } } }
        end

        let(:end_user) { build(:end_user) }

        it 'should not create a Ta' do
          instructor
          expect { subject }.not_to(change { Instructor.count })
        end

        it 'should display an error message' do
          subject
          expect(flash[:error]).not_to be_empty
        end
      end

      context 'when trying to assign to a non end user' do
        subject do
          post_as instructor, :create,
                  params: { course_id: course.id, role: { end_user: { user_name: admin_user.user_name } } }
        end

        let(:admin_user) { create(:admin_user) }

        it 'should not create an instructor' do
          instructor
          expect { subject }.not_to(change { Instructor.count })
        end

        it 'should display an error message' do
          subject
          expect(flash[:error]).not_to be_empty
        end
      end
    end

    describe '#update' do
      subject do
        post_as instructor, :update,
                params: { course_id: course.id, id: role, role: { end_user: { user_name: new_end_user.user_name } } }
      end

      it_behaves_like 'role is from a different course' do
        subject do
          post_as new_role, :update,
                  params: { course_id: course.id, id: role, role: { end_user: { user_name: end_user.user_name } } }
        end
      end

      context 'when the new user exists' do
        let(:new_end_user) { create(:end_user) }

        it 'should change the user' do
          subject
          expect(role.reload.user).to eq(new_end_user)
        end

        context 'when updating user visibility' do
          it 'should not update the user' do
            post_as instructor, :update,
                    params: {
                      course_id: course.id,
                      id: role,
                      role: { end_user: { user_name: new_end_user.user_name }, hidden: true }
                    }
            expect(role.reload.hidden).to be(false)
          end
        end
      end

      context 'when the user does not exist' do
        let(:new_end_user) { build(:end_user) }

        it 'should not change the user' do
          old_user = role.user
          subject
          expect(role.reload.user).to eq(old_user)
        end

        it 'should display an error message' do
          subject
          expect(flash[:error]).not_to be_empty
        end
      end

      context 'when trying to assign to a non end user' do
        let(:new_end_user) { create(:admin_user) }

        it 'should not change the user' do
          old_user = role.user
          subject
          expect(role.reload.user).to eq(old_user)
        end

        it 'should display an error message' do
          subject
          expect(flash[:error]).not_to be_empty
        end
      end
    end
  end
end
