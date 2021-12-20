describe Api::MainApiController do
  context 'a non-existant route' do
    it 'should reroute to page_not_found' do
      expect(get: '/api/badroute').to route_to(controller: 'api/main_api', action: 'page_not_found', path: 'badroute')
    end
  end
end
