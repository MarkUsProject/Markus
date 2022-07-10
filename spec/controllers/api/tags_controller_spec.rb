describe Api::TagsController do
  let(:assignment) { create :assignment_with_criteria_and_results }
  let(:grouping) { create :grouping, assignment: assignment }
  let(:tag) { create :tag, assessment: assignment, groupings: [grouping] }
  context 'An unauthenticated request' do
    before :each do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it 'should fail to authenticate a GET index request' do
      get :index, params: { assignment_id: assignment.id, grouping_id: grouping.id }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a GET show request' do
      get :show, params: { assignment_id: assignment.id, grouping_id: grouping.id }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a POST create request' do
      post :create, params: { tag: tag, name: 'new_tag', description: 'desc' }
      expect(response).to have_http_status(403)
    end

    it 'should fail to authenticate a PUT update request' do
      post :update, params: { tag: tag, name: 'update_tag', description: 'desc' }
      expect(response).to have_http_status(403)
    end
  end
end
