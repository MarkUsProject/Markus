describe Api::TagsController do
  let(:course) { create(:course) }
  let(:assignment) { create(:assignment_with_criteria_and_results, course: course) }
  let(:grouping) { create(:grouping, assignment: assignment) }
  let!(:tag) { create(:tag, course: course, groupings: [grouping]) }
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

    it 'should fail to authenticate a POST create request' do
      post :create, params: { course_id: course.id, assignment_id: assignment.id, grouping_id: grouping.id, tag: tag }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a PUT update request' do
      put :update, params: { course_id: course.id, id: tag.id, name: 'new_name' }
      expect(response).to have_http_status(:forbidden)
    end

    it 'should fail to authenticate a DELETE destroy request' do
      delete :destroy, params: { course_id: course.id, id: tag.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'An authenticated user requesting' do
    before do
      instructor.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{instructor.api_key.strip}"
    end

    context 'GET index' do
      context 'expecting an xml response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/xml'
          get :index, params: { course_id: course.id }
        end

        it 'should be successful' do
          expect(response).to have_http_status(:ok)
        end

        it 'should return xml content' do
          expect(Hash.from_xml(response.body)['objects'][0]['id']).to eq(tag.id)
        end
      end

      context 'expecting a json response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/json'
          get :index, params: { course_id: course.id }
        end

        it 'should be successful' do
          expect(response).to have_http_status(:ok)
        end

        it 'should return json content' do
          expect(response.parsed_body&.first&.dig('id')).to eq(tag.id)
        end
      end
    end

    context 'POST create' do
      before do
        request.env['HTTP_ACCEPT'] = 'application/xml'
      end

      it 'should create a new tag when given the correct params' do
        post :create, params: { course_id: course.id, name: 'new_tag', assignment_id: assignment.id }
        expect(response).to have_http_status(:created)
        expect(Tag.find_by(name: 'new_tag').name).to eq('new_tag')
      end

      it 'should create a new tag when given the correct params with grouping_id' do
        post :create, params: { course_id: course.id, name: 'new_tag', assignment_id: assignment.id,
                                grouping_id: grouping.id }
        expect(response).to have_http_status(:created)
        expect(Tag.find_by(name: 'new_tag').groupings.first).to eq(grouping)
      end

      it 'should throw a 404 error if there is not a valid course_id' do
        post :create, params: { course_id: course.id + 1, name: 'new_tag' }
        expect(response).to have_http_status(:not_found)
      end

      it 'should throw a 422 error if the grouping id is not valid' do
        post :create, params: { course_id: course.id, name: 'new_tag', assignment_id: assignment.id,
                                grouping_id: grouping.id + 1 }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'should throw a 422 error if the assignment id is not valid' do
        post :create, params: { course_id: course.id, name: 'new_tag', assignment_id: assignment.id + 1,
                                grouping_id: grouping.id }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'PUT update' do
      before do
        request.env['HTTP_ACCEPT'] = 'application/xml'
      end

      it 'should update a tags name if given a name and a valid tag' do
        put :update, params: { course_id: course.id, id: tag.id, name: 'new_name' }
        expect(response).to have_http_status(:ok)
        tag.reload
        expect(tag.name).to eq('new_name')
      end

      it 'should update just the description' do
        put :update, params: { course_id: course.id, id: tag.id, description: 'new_desc' }
        expect(response).to have_http_status(:ok)
        tag.reload
        expect(tag.description).to eq('new_desc')
      end

      it 'should update a tags name and description if given a name and a valid tag' do
        put :update, params: { course_id: course.id, id: tag.id, description: 'new_desc', name: 'new_name' }
        expect(response).to have_http_status(:ok)
        tag.reload
        expect(tag.description).to eq('new_desc')
        expect(tag.name).to eq('new_name')
      end

      it 'should throw 404 if tag does not exist' do
        put :update, params: { course_id: course.id, id: tag.id + 1, description: 'new_desc' }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'DELETE destroy' do
      before do
        request.env['HTTP_ACCEPT'] = 'application/xml'
      end

      it 'should send 404 back if the tag does not exist' do
        delete :destroy, params: { course_id: course.id, id: tag.id + 1 }
        expect(response).to have_http_status(:not_found)
      end

      it 'should delete a tag' do
        old_id = tag.id
        delete :destroy, params: { course_id: course.id, id: tag.id }
        expect(response).to have_http_status(:ok)

        expect(Tag.find_by(id: old_id)).to be_nil
      end
    end
  end
end
