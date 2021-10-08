describe CoursesController do
  let(:admin) { create :admin }
  let(:course) { create :course }
  context 'accessing course pages' do
    it 'responds with success on index' do
      get_as admin, :index
      expect(response.status).to eq(200)
    end
    it 'responds with success on show' do
      get_as admin, :show, params: { id: course }
      expect(response.status).to eq(200)
    end
  end
end
