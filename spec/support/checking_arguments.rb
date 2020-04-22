shared_examples 'Invalid_arguments' do
  context 'When the assignment has no submission' do
    it 'should respond with 404' do
      post :create_extra_marks, params: { assignment_id: grouping.assignment.id,
                                          id: grouping.group.id,
                                          extra_marks: 10,
                                          description: 'sample' }
      expect(response.status).to eq(404)
    end
  end
  context 'when the assignment doest not exist ' do
    it 'should respond with 404' do
      post :create_extra_marks, params: { assignment_id: 9999,
                                          id: grouping.group.id,
                                          extra_marks: 10,
                                          description: 'sample' }
      expect(response.status).to eq(404)
    end
  end
  context 'when the group does not exist' do
    it 'should respond with 404' do
      post :create_extra_marks, params: { assignment_id: grouping.assignment.id,
                                          id: 9999,
                                          extra_marks: 10,
                                          description: 'sample' }
      expect(response.status).to eq(404)
    end
  end
end
