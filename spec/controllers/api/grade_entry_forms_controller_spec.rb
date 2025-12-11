describe Api::GradeEntryFormsController do
  let(:course) { create(:course) }
  let(:grade_entry_form) { create(:grade_entry_form, course: course) }

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
      get :show, params: { id: grade_entry_form.id, course_id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a POST create request' do
      post :create, params: { course_id: course.id }

      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a PUT update request' do
      put :update, params: { id: grade_entry_form.id, course_id: course.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'An authenticated request requesting' do
    before do
      instructor = create(:instructor, course: course)
      instructor.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{instructor.api_key.strip}"
    end

    context 'GET index' do
      context 'expecting an xml response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/xml'
        end

        context 'with a single grade entry form' do
          before do
            grade_entry_form
            get :index, params: { course_id: course.id }
          end

          it 'should be successful' do
            expect(response).to have_http_status(:ok)
          end

          it 'should return xml content' do
            expect(Hash.from_xml(response.body)
                       .dig('grade_entry_forms', 'grade_entry_form', 'id')).to eq(grade_entry_form.id.to_s)
          end

          it 'should return all default fields' do
            keys = Hash.from_xml(response.body).dig('grade_entry_forms', 'grade_entry_form').keys.map(&:to_sym)
            expect(keys).to contain_exactly(:grade_entry_items, *Api::GradeEntryFormsController::DEFAULT_FIELDS)
          end
        end

        context 'with a single grade entry form in a different course' do
          before do
            create(:grade_entry_form, course: create(:course))
            get :index, params: { course_id: course.id }
          end

          it 'should be successful' do
            expect(response).to have_http_status(:ok)
          end

          it 'should return empty content' do
            expect(Hash.from_xml(response.body)['grade_entry_forms']).to be_nil
          end
        end

        context 'with multiple assignments' do
          before do
            create_list(:grade_entry_form, 5, course: course)
            get :index, params: { course_id: course.id }
          end

          it 'should return xml content about all grade entry forms' do
            expect(Hash.from_xml(response.body).dig('grade_entry_forms', 'grade_entry_form').length).to eq(5)
          end

          it 'should return all default fields for all grade entry forms' do
            keys = Hash.from_xml(response.body)
                       .dig('grade_entry_forms', 'grade_entry_form')
                       .map { |h| h.keys.map(&:to_sym) }
            expect(keys).to all(contain_exactly(:grade_entry_items, *Api::GradeEntryFormsController::DEFAULT_FIELDS))
          end
        end

        context 'with multiple grade entry forms in a different course' do
          before do
            create_list(:grade_entry_form, 5, course: create(:course))
            get :index, params: { course_id: course.id }
          end

          it 'should be successful' do
            expect(response).to have_http_status(:ok)
          end

          it 'should return empty content' do
            expect(Hash.from_xml(response.body)['grade_entry_forms']).to be_nil
          end
        end
      end

      context 'expecting a json response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/json'
        end

        context 'with a single grade entry form' do
          before do
            grade_entry_form
            get :index, params: { course_id: course.id }
          end

          it 'should be successful' do
            expect(response).to have_http_status(:ok)
          end

          it 'should return json content' do
            expect(response.parsed_body&.first&.dig('id')).to eq(grade_entry_form.id)
          end

          it 'should return all default fields' do
            keys = response.parsed_body&.first&.keys&.map(&:to_sym)
            expect(keys).to contain_exactly(:grade_entry_items, *Api::GradeEntryFormsController::DEFAULT_FIELDS)
          end
        end

        context 'with a single grade entry form in a different course' do
          before do
            create(:grade_entry_form, course: create(:course))
            get :index, params: { course_id: course.id }
          end

          it 'should be successful' do
            expect(response).to have_http_status(:ok)
          end

          it 'should return empty content' do
            expect(response.parsed_body&.first&.dig('id')).to be_nil
          end
        end

        context 'with multiple grade entry forms' do
          before do
            create_list(:grade_entry_form, 5, course: course)
            get :index, params: { course_id: course.id }
          end

          it 'should return xml content about all grade entry forms' do
            expect(response.parsed_body.length).to eq(5)
          end

          it 'should return all default fields for all grade entry forms' do
            keys = response.parsed_body.map { |h| h.keys.map(&:to_sym) }
            expect(keys).to all(contain_exactly(:grade_entry_items, *Api::GradeEntryFormsController::DEFAULT_FIELDS))
          end
        end

        context 'with a multiple grade entry forms in a different course' do
          before do
            create_list(:grade_entry_form, 5, course: create(:course))
            get :index, params: { course_id: course.id }
          end

          it 'should be successful' do
            expect(response).to have_http_status(:ok)
          end

          it 'should return empty content' do
            expect(response.parsed_body&.first&.dig('id')).to be_nil
          end
        end
      end
    end

    context 'GET show' do
      context 'requesting an existant grade entry form' do
        before { get :show, params: { id: grade_entry_form.id, course_id: course.id } }

        it 'should download a basic csv' do
          csv_array = [
            Student::CSV_ORDER.map { |field| GradeEntryForm.human_attribute_name(field) },
            [''] * (Student::CSV_ORDER.length - 1) +
              [GradeEntryItem.human_attribute_name(:out_of)]
          ]
          csv_data = MarkusCsv.generate(csv_array, &:itself)
          expect(response.body).to eq csv_data
        end
        # TODO: add more tests
      end

      context 'requesting a non-existant grade entry form' do
        it 'should respond with 404' do
          get :show, params: { id: -1, course_id: course.id }
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'requesting a grade entry form in a different course' do
        it 'should response with 403' do
          grade_entry_form = create(:grade_entry_form, course: create(:course))
          get :show, params: { id: grade_entry_form.id, course_id: grade_entry_form.course_id }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'POST create' do
      let(:params) do
        { short_identifier: 'A0', description: 'Test', course_id: course.id }
      end
      let(:full_params) do
        { short_identifier: 'A0', course_id: course.id, description: 'Test',
          due_date: '2012-03-26 18:04:39', is_hidden: false,
          grade_entry_items: [
            { name: 'col1', out_of: 10, bonus: false },
            { name: 'col2', out_of: 2, bonus: true }
          ] }
      end

      context 'with minimal required params' do
        it 'should respond with 201' do
          post :create, params: params
          expect(response).to have_http_status(:created)
        end

        it 'should create an assignment' do
          expect(GradeEntryForm.find_by(short_identifier: params[:short_identifier])).to be_nil
          post :create, params: params
          expect(GradeEntryForm.find_by(short_identifier: params[:short_identifier])).not_to be_nil
        end

        context 'for a different course' do
          it 'should response with 403' do
            post :create, params: { **params, course_id: create(:course).id }
            expect(response).to have_http_status(:forbidden)
          end
        end
      end

      context 'with all params' do
        it 'should respond with 201' do
          post :create, params: params
          expect(response).to have_http_status(:created)
        end

        it 'should create an assignment' do
          expect(GradeEntryForm.find_by(short_identifier: params[:short_identifier])).to be_nil
          post :create, params: params
          expect(GradeEntryForm.find_by(short_identifier: params[:short_identifier])).not_to be_nil
        end
      end

      context 'with missing params' do
        context 'missing short_id' do
          it 'should respond with 422' do
            post :create, params: params.slice(:description, :due_date, :course_id)
            expect(response).to have_http_status(:unprocessable_content)
          end

          it 'should not create an assignment' do
            post :create, params: params.slice(:description, :due_date, :course_id)
            expect(Assignment.find_by(description: params[:description])).to be_nil
          end
        end

        context 'missing description' do
          it 'should respond with 422' do
            post :create, params: params.slice(:short_identifier, :due_date, :course_id)
            expect(response).to have_http_status(:unprocessable_content)
          end

          it 'should not create an assignment' do
            post :create, params: params.slice(:short_identifier, :due_date, :course_id)
            expect(GradeEntryForm.find_by(short_identifier: params[:short_identifier])).to be_nil
          end
        end
      end

      context 'where short_identifier is already taken' do
        it 'should respond with 409' do
          grade_entry_form = create(:grade_entry_form, course: course)
          post :create, params: { **params, short_identifier: grade_entry_form.short_identifier }
          expect(response).to have_http_status(:conflict)
        end
      end

      context 'where due_date is invalid' do
        it 'should respond with 422' do
          post :create, params: { **params, due_date: 'not a real date' }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    context 'PUT update' do
      it 'should update an existing assignment' do
        new_desc = grade_entry_form.description + 'more!'
        put :update, params: { id: grade_entry_form.id, description: new_desc, course_id: course.id }
        expect(response).to have_http_status(:ok)
      end

      it 'should not update a short identifier' do
        new_short_id = grade_entry_form.short_identifier + 'more!'
        put :update, params: { id: grade_entry_form.id, short_identifier: new_short_id, course_id: course.id }
        expect(response).to have_http_status(:internal_server_error)
      end

      it 'should not update an assignment that does not exist' do
        new_desc = grade_entry_form.description + 'more!'
        put :update, params: { id: -1, description: new_desc, course_id: course.id }
        expect(response).to have_http_status(:not_found)
      end

      context 'for a different course' do
        let(:grade_entry_form) { create(:grade_entry_form, course: create(:course)) }

        it 'should response with 403' do
          new_desc = grade_entry_form.description + 'more!'
          put :update, params: { id: grade_entry_form.id, description: new_desc, course_id: grade_entry_form.course.id }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'PUT update_grades' do
      let(:student) { create(:student) }
      let(:grade_params) do
        { short_identifier: 'A0', course_id: course.id, description: 'Test',
          due_date: '2012-03-26 18:04:39', is_hidden: false,
          id: grade_entry_form.id,
          grade_entry_items: [
            { name: 'col1', out_of: 10, bonus: false },
            { name: 'col2', out_of: 2, bonus: true }
          ] }
      end

      before { create(:grade_entry_item, grade_entry_form: grade_entry_form, out_of: 5, name: 'col1') }

      it 'creates new grades' do
        put :update_grades,
            params: { course_id: course.id, id: grade_entry_form.id, user_name: student.user_name,
                      grade_entry_items: { col1: 2 } }
        expect(grade_entry_form.grade_entry_students.find_by(role: student).grades.count).to eq(1)
      end

      it 'updates existing grades' do
        put :update_grades,
            params: { course_id: course.id, id: grade_entry_form.id, user_name: student.user_name,
                      grade_entry_items: { col1: 2 } }
        put :update_grades,
            params: { course_id: course.id, id: grade_entry_form.id, user_name: student.user_name,
                      grade_entry_items: { col1: 5 } }
        expect(grade_entry_form.grade_entry_students.find_by(role: student).grades.first.grade).to eq(5)
      end
    end

    context 'DELETE Destroy' do
      it 'does not delete a non-existing grade entry form' do
        delete :destroy, params: { course_id: course.id, id: -1 }
        expect(response).to have_http_status(:not_found)
      end

      it 'successfully deletes a grade entry form with no non-nil grades' do
        form = create(:grade_entry_form, course_id: course.id, id: 4)
        first_student = create(:student)
        second_student = create(:student)
        grade_entry_item = create(:grade_entry_item, out_of: 10, grade_entry_form: form)
        create(:grade, grade_entry_student: form.grade_entry_students.find_by(role: first_student),
                       grade_entry_item: grade_entry_item, grade: nil)
        create(:grade, grade_entry_student: form.grade_entry_students.find_by(role: second_student),
                       grade_entry_item: grade_entry_item, grade: nil)
        delete :destroy, params: { course_id: course.id, id: 4 }
        expect(response).to have_http_status(:ok)
        expect(course.grade_entry_forms).not_to exist(form.id)
      end

      it 'does not delete a grade entry form with non-nil grades' do
        form = create(:grade_entry_form, course_id: course.id, id: 4)
        first_student = create(:student)
        second_student = create(:student)
        grade_entry_item = create(:grade_entry_item, out_of: 10, grade_entry_form: form)
        create(:grade, grade_entry_student: form.grade_entry_students.find_by(role: first_student),
                       grade_entry_item: grade_entry_item, grade: nil)
        create(:grade, grade_entry_student: form.grade_entry_students.find_by(role: second_student),
                       grade_entry_item: grade_entry_item, grade: 0.2)
        delete :destroy, params: { course_id: course.id, id: 4 }
        expect(response).to have_http_status(:conflict)
        expect(course.grade_entry_forms).to exist(form.id)
      end
    end
  end
end
