describe MarkingSchemesController do
  let(:grade_entry_form) { create(:grade_entry_form) }
  let(:grade_entry_form_with_data) { create(:grade_entry_form_with_data) }
  let(:assignment) { create(:assignment) }
  let(:assignment_with_criteria_and_results) { create(:assignment_with_criteria_and_results) }
  let(:admin) { create(:admin) }

  describe 'An unauthenticated and unauthorized user' do
    context '#index' do
      it 'should respond with redirect' do
        get :index
        is_expected.to respond_with :redirect
      end
    end

    context '#new' do
      it 'should respond with redirect' do
        post :new
        is_expected.to respond_with :redirect
      end
    end

    context '#populate' do
      it 'should respond with redirect' do
        get :populate
        is_expected.to respond_with :redirect
      end
    end
  end

  describe 'An authorized user' do
    context '#populate' do
      let(:assessments) do
        [grade_entry_form,
         grade_entry_form_with_data,
         assignment,
         assignment_with_criteria_and_results]
      end
      before do
        create :marking_scheme, assessments: assessments
        get_as admin, :populate, format: :json
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
    end

    context '#new' do
      before(:each) do
        get_as admin, :new, format: :js
      end

      it 'should render the new template' do
        is_expected.to render_template(:new)
      end

      it 'should respond with success' do
        is_expected.to respond_with(:success)
      end
    end

    context '#edit' do
      before(:each) do
        create(
          :marking_scheme,
          assessments: [
            grade_entry_form,
            grade_entry_form_with_data,
            assignment,
            assignment_with_criteria_and_results
          ]
        )

        post_as admin,
                :edit,
                params: { id: MarkingScheme.first.id },
                format: :js
      end

      it 'should render the edit template' do
        is_expected.to render_template(:edit)
      end

      it 'should respond with success' do
        is_expected.to respond_with(:success)
      end
    end

    context '#destroy' do
      it ' should be able to delete the marking scheme' do
        create(
          :marking_scheme,
          assessments: [
            grade_entry_form,
            grade_entry_form_with_data,
            assignment,
            assignment_with_criteria_and_results
          ]
        )

        ms = MarkingScheme.first
        delete_as admin,
                  :destroy,
                  params: { id: ms.id },
                  format: :js
        is_expected.to respond_with(:success)
        expect { MarkingScheme.find(ms.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
