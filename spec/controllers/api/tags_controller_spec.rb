describe Api::TagsController do
  let(:assignment) { create :assignment_with_criteria_and_results }
  let(:grouping) { create :grouping, assignment: assignment }
  let(:tag) { create :tag, assessment: assignment, groupings: [grouping] }
  let(:instructor) { create :instructor, course: assignment.course }
  context 'An unauthenticated request' do
    before :each do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it 'should fail to authenticate a GET index request' do
      get :index, params: { assignment_id: assignment.id }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a POST create request' do
      post :create, params: { assignment_id: assignment.id, grouping_id: grouping.id, tag: tag }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a PUT update request' do
      put :update, params: { id: tag.id, name: 'new_name' }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a PUT add_tag request' do
      put :add_tag, params: { id: tag.id, result_id: grouping.results.first }
      expect(response).to have_http_status(403)
    end
    it 'should fail to authenticate a PUT remove_tag request' do
      put :remove_tag, params: { id: tag.id, result_id: grouping.results.first }
      expect(response).to have_http_status(403)
    end
  end

  context 'An authenticated user requesting' do
    before :each do
      instructor.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{instructor.api_key.strip}"
    end

    context 'GET index' do
      context 'expecting an xml response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/xml'
          get :index, params: { assignment_id: assignment.id }
        end

        it 'should be successful' do
          expect(response.status).to eq(200)
        end

        it 'should return xml content' do
          expect(Hash.from_xml(response.body).dig('tags', 'tag')).to eq(assignment.tags.ids.to_s)
        end
      end
      context 'expecting a json response' do
        before :each do
          request.env['HTTP_ACCEPT'] = 'application/json'
          get :index, params: { assignment_id: assignment.id }
        end

        it 'should be successful' do
          expect(response.status).to eq(200)
        end

        it 'should return json content' do
          expect(JSON.parse(response.body)&.first&.dig('id')).to eq(tag.id)
        end
      end
    end
  end
end
