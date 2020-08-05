describe MarkingSchemesController do
  let(:grade_entry_form) { create(:grade_entry_form) }
  let(:grade_entry_form_with_data) { create(:grade_entry_form_with_data) }
  let(:assignment) { create(:assignment) }
  let(:assignment_with_criteria_and_results) { create(:assignment_with_criteria_and_results) }
  let(:marking_scheme) { create(:marking_scheme, assessments: [assignment]) }
  shared_examples 'An authorized user' do
    context 'POST create' do
      let(:params) do
        { marking_scheme: { name: 'Scheme B',
                            marking_weights_attributes: { '0' => { id: assignment, weight: '2' } } } }
      end
      before { post_as user, :create, params: params }
      it('should respond with 302') { expect(response.status).to eq 302 }
    end
    context 'GET new' do
      before { get_as user, :new }
      it('should respond with 200') { expect(response.status).to eq 200 }
    end
    context 'GET populate' do
      let(:assessments) do
        [grade_entry_form,
         grade_entry_form_with_data,
         assignment,
         assignment_with_criteria_and_results]
      end
      before do
        create :marking_scheme, assessments: assessments
        get_as user, :populate, format: :json
      end
      it 'returns a hash with the correct keys' do
        expect(response.parsed_body.keys).to contain_exactly('data', 'columns')
      end
      it 'returns a nested data hash with the correct keys' do
        expected_keys = %w[id name assessment_weights edit_link delete_link]
        expect(response.parsed_body['data'][0].keys).to contain_exactly(*expected_keys)
      end
      it 'should contain the correct weights' do
        expected_assessment_ids = assessments.map(&:id).map(&:to_s)
        expect(response.parsed_body['data'][0]['assessment_weights'].keys).to contain_exactly(*expected_assessment_ids)
      end
      it 'should contain the correct column accessors' do
        accessors = response.parsed_body['columns'].map { |c| c['accessor'] }
        expect(accessors).to contain_exactly(*assessments.map { |a| "assessment_weights.#{a.id}" })
      end
      it('should respond with 200') { expect(response.status).to eq 200 }
    end

    context '#create' do
      it 'creates a marking scheme with marking weights' do
        params = {
          'marking_scheme': {
            'name': 'Test Marking Scheme',
            'marking_weights_attributes': {
              '0': { 'id': assignment, 'weight': 1 },
              '1': { 'id': assignment_with_criteria_and_results, 'weight': 2 }
            }
          }
        }

        post_as admin, :create, params: params
        marking_scheme = MarkingScheme.first
        marking_weights = marking_scheme.marking_weights
        expect(marking_scheme.name).to eq 'Test Marking Scheme'
        expect(marking_weights.size).to eq 2

        expected_ids = [assignment.id, assignment_with_criteria_and_results.id]
        expect(marking_weights.map(&:assessment_id)).to match_array expected_ids
      end

      it 'creates a marking scheme when there are no assessments' do
        params = {
          'marking_scheme': { 'name': 'Test Marking Scheme' }
        }

        post_as admin, :create, params: params
        marking_scheme = MarkingScheme.first
        marking_weights = marking_scheme.marking_weights
        expect(marking_scheme.name).to eq 'Test Marking Scheme'
        expect(marking_weights.size).to eq 0
      end
      it('should respond with 302') { expect(response.status).to eq 302 }
    end

    context '#update' do
      it 'updates an existing marking scheme with new marking weights' do
        create(
          :marking_scheme,
          assessments: [
            grade_entry_form,
            grade_entry_form_with_data,
            assignment,
            assignment_with_criteria_and_results
          ]
        )
        params = {
          'id': MarkingScheme.first.id,
          'marking_scheme': {
            'name': 'Test Marking Scheme 2',
            'marking_weights_attributes': {
              '0': { 'id': assignment, 'weight': 2.5 },
              '1': { 'id': assignment_with_criteria_and_results, 'weight': 3.5 },
              '2': { 'id': grade_entry_form, 'weight': 1.5 },
              '3': { 'id': grade_entry_form_with_data, 'weight': 0 }
            }
          }
        }

        post_as admin, :update, params: params
        marking_scheme = MarkingScheme.first
        marking_weights = marking_scheme.marking_weights
        expected_weights = [2.5, 3.5, 1.5, 0]
        expect(marking_scheme.name).to eq 'Test Marking Scheme 2'
        expect(marking_weights.size).to eq 4
        expect(marking_weights.map(&:weight)).to match_array expected_weights
      end

      it 'updates an existing marking scheme with no assessments' do
        create(:marking_scheme)
        params = {
          'id': MarkingScheme.first.id,
          'marking_scheme': { 'name': 'Test Marking Scheme 2' }
        }

        post_as admin, :update, params: params
        marking_scheme = MarkingScheme.first
        marking_weights = marking_scheme.marking_weights
        expect(marking_scheme.name).to eq 'Test Marking Scheme 2'
        expect(marking_weights.size).to eq 0
      end
      it('should respond with 302') { expect(response.status).to eq 302 }
    end
    context 'DELETE destroy' do
      before { delete_as user, :destroy, params: { id: marking_scheme.id } }
      it('should respond with 200') { expect(response.status).to eq 200 }
    end
    context 'GET edit' do
      before { get_as user, :edit, params: { id: marking_scheme.id } }
      it('should respond with 200') { expect(response.status).to eq 200 }
    end
    context 'PUT update' do
      let(:params) do
        { id: marking_scheme.id,
          marking_scheme: { name: 'Scheme C',
                            marking_weights_attributes: { '0' => { id: assignment, weight: '2' } } } }
      end
      before { put_as user, :update, params: params }
      it('should respond with 302') { expect(response.status).to eq 302 }
    end
    context 'GET index' do
      before { get_as user, :index }
      it('should respond with 200') { expect(response.status).to eq 200 }
    end
  end

  describe 'an authenticated admin' do
    let!(:user) { create(:admin) }
    include_examples 'An authorized user'
  end

  describe 'When the grader is allowed to manage marking schemes' do
    let!(:user) { create(:ta) }
    before do
      user.grader_permission.manage_course_grades = true
      user.grader_permission.save
    end
    include_examples 'An authorized user'
  end

  describe 'When the grader is not allowed to manage marking schemes' do
    let(:grader) { create(:ta) }
    before do
      grader.grader_permission.manage_course_grades = false
      grader.grader_permission.save
    end
    context 'POST create' do
      let(:params) do
        { marking_scheme: { name: 'Scheme D',
                            marking_weights_attributes: { '0' => { id: assignment, weight: '2' } } } }
      end
      before { post_as grader, :create, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET new' do
      before { get_as grader, :new }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET populate' do
      before { get_as grader, :populate }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'DELETE destroy' do
      before { delete_as grader, :destroy, params: { id: marking_scheme.id } }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET edit' do
      before { get_as grader, :edit, params: { id: marking_scheme.id } }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'PUT update' do
      let(:params) do
        { id: marking_scheme.id,
          marking_scheme: { name: 'Scheme E',
                            marking_weights_attributes: { '0' => { id: assignment, weight: '10' } } } }
      end
      before { put_as grader, :update, params: params }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
    context 'GET index' do
      before { get_as grader, :index }
      it('should respond with 403') { expect(response.status).to eq 403 }
    end
  end
end
