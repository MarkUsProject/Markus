describe MarkingSchemesController do
  # TODO: add 'role is from a different course' shared tests to each route test below
  let(:grade_entry_form) { create(:grade_entry_form) }
  let(:grade_entry_form_with_data) { create(:grade_entry_form_with_data) }
  let(:assignment) { create(:assignment) }
  let(:assignment_with_criteria_and_results) { create(:assignment_with_criteria_and_results) }
  let(:instructor) { create(:instructor) }
  let(:course) { instructor.course }

  describe 'An unauthenticated and unauthorized user' do
    describe '#index' do
      it 'should respond with redirect' do
        get :index, params: { course_id: course.id }
        expect(subject).to respond_with :redirect
      end
    end

    describe '#new' do
      it 'should respond with redirect' do
        post :new, params: { course_id: course.id }
        expect(subject).to respond_with :redirect
      end
    end

    describe '#populate' do
      it 'should respond with redirect' do
        get :populate, params: { course_id: course.id }
        expect(subject).to respond_with :redirect
      end
    end
  end

  describe 'An authorized user' do
    describe '#populate' do
      let(:assessments) do
        [grade_entry_form,
         grade_entry_form_with_data,
         assignment,
         assignment_with_criteria_and_results]
      end

      before do
        create(:marking_scheme, assessments: assessments)
        get_as instructor, :populate, params: { course_id: course.id }, format: :json
      end

      it 'returns a hash with the correct keys' do
        expect(response.parsed_body.keys).to contain_exactly('data', 'columns')
      end

      it 'returns a nested data hash with the correct keys' do
        expected_keys = %w[id name assessment_weights edit_link delete_link]
        expect(response.parsed_body['data'][0].keys).to match_array(expected_keys)
      end

      it 'should contain the correct weights' do
        expected_assessment_ids = assessments.map { |a| a.id.to_s }
        expect(response.parsed_body['data'][0]['assessment_weights'].keys).to match_array(expected_assessment_ids)
      end

      it 'should contain the correct column accessors' do
        accessors = response.parsed_body['columns'].pluck('accessor')
        expect(accessors).to match_array(assessments.map { |a| "assessment_weights.#{a.id}" })
      end
    end

    describe '#create' do
      it 'creates a marking scheme with marking weights' do
        params = {
          course_id: course.id,
          marking_scheme: {
            name: 'Test Marking Scheme',
            marking_weights_attributes: {
              '0': { id: assignment, weight: 1 },
              '1': { id: assignment_with_criteria_and_results, weight: 2 }
            }
          }
        }

        post_as instructor, :create, params: params
        marking_scheme = MarkingScheme.first
        marking_weights = marking_scheme.marking_weights
        expect(marking_scheme.name).to eq 'Test Marking Scheme'
        expect(marking_weights.size).to eq 2

        expected_ids = [assignment.id, assignment_with_criteria_and_results.id]
        expect(marking_weights.map(&:assessment_id)).to match_array expected_ids
      end

      it 'creates a marking scheme when there are no assessments' do
        params = { course_id: course.id, marking_scheme: { name: 'Test Marking Scheme' } }

        post_as instructor, :create, params: params
        marking_scheme = MarkingScheme.first
        marking_weights = marking_scheme.marking_weights
        expect(marking_scheme.name).to eq 'Test Marking Scheme'
        expect(marking_weights.size).to eq 0
      end
    end

    describe '#update' do
      it 'updates an existing marking scheme with new marking weights' do
        create(:marking_scheme,
               assessments: [grade_entry_form,
                             grade_entry_form_with_data,
                             assignment,
                             assignment_with_criteria_and_results])
        params = {
          course_id: course.id,
          id: MarkingScheme.first.id,
          marking_scheme: {
            name: 'Test Marking Scheme 2',
            marking_weights_attributes: {
              '0': { id: assignment, weight: 2.5 },
              '1': { id: assignment_with_criteria_and_results, weight: 3.5 },
              '2': { id: grade_entry_form, weight: 1.5 },
              '3': { id: grade_entry_form_with_data, weight: 0 }
            }
          }
        }

        post_as instructor, :update, params: params
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
          course_id: course.id,
          id: MarkingScheme.first.id,
          marking_scheme: { name: 'Test Marking Scheme 2' }
        }

        post_as instructor, :update, params: params
        marking_scheme = MarkingScheme.first
        marking_weights = marking_scheme.marking_weights
        expect(marking_scheme.name).to eq 'Test Marking Scheme 2'
        expect(marking_weights.size).to eq 0
      end

      it 'should save weights for newly added assessments' do
        marking_scheme = create(
          :marking_scheme,
          assessments: [assignment]
        )

        new_assignment = create(:assignment, course: course)

        params = {
          course_id: course.id,
          id: marking_scheme.id,
          marking_scheme: {
            name: 'Updated Scheme',
            marking_weights_attributes: {
              '0': { id: assignment.id, weight: 10 },
              '1': { id: new_assignment.id, weight: 15 }
            }
          }
        }

        post_as instructor, :update, params: params

        marking_scheme.reload
        expect(marking_scheme.marking_weights.count).to eq 2

        new_weight = marking_scheme.marking_weights.find_by(assessment_id: new_assignment.id)
        expect(new_weight).not_to be_nil
        expect(new_weight.weight).to eq 15
      end
    end

    describe '#new' do
      before do
        get_as instructor, :new, params: { course_id: course.id }, format: :js
      end

      it 'should render the new template' do
        expect(subject).to render_template(:new)
      end

      it 'should respond with success' do
        expect(subject).to respond_with(:success)
      end
    end

    describe '#edit' do
      before do
        create(
          :marking_scheme,
          assessments: [
            grade_entry_form,
            grade_entry_form_with_data,
            assignment,
            assignment_with_criteria_and_results
          ]
        )

        post_as instructor,
                :edit,
                params: { course_id: course.id, id: MarkingScheme.first.id },
                format: :js
      end

      it 'should render the edit template' do
        expect(subject).to render_template(:edit)
      end

      it 'should respond with success' do
        expect(subject).to respond_with(:success)
      end

      context 'when new assessments are added after marking scheme is created' do
        it 'should include new assessments in the edit form' do
          marking_scheme = create(
            :marking_scheme,
            assessments: [assignment, grade_entry_form]
          )

          new_assignment = create(:assignment, course: course)
          new_grade_entry_form = create(:grade_entry_form, course: course)

          get_as instructor,
                 :edit,
                 params: { course_id: course.id, id: marking_scheme.id },
                 format: :js

          # Check @all_gradable_items includes the new assessments
          expect(assigns(:all_gradable_items)).to include(new_assignment, new_grade_entry_form)
        end

        it 'should display correct marking weights for each assessment' do
          marking_scheme = create(
            :marking_scheme,
            assessments: [assignment, grade_entry_form]
          )

          new_assignment = create(:assignment, course: course)

          get_as instructor,
                 :edit,
                 params: { course_id: course.id, id: marking_scheme.id },
                 format: :js

          # Check all current assessments in @all_gradable_items
          all_assessments = assigns(:all_gradable_items)
          expect(all_assessments).to include(assignment, grade_entry_form, new_assignment)

          # Check existing marking weights still present
          marking_weights = assigns(:marking_scheme).marking_weights
          expect(marking_weights.find { |mw| mw.assessment_id == assignment.id }).not_to be_nil
          expect(marking_weights.find { |mw| mw.assessment_id == grade_entry_form.id }).not_to be_nil

          # Check new assignment in @all_gradable_items
          expect(all_assessments).to include(new_assignment)
        end
      end
    end

    describe '#destroy' do
      it 'should be able to delete the marking scheme' do
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
        delete_as instructor,
                  :destroy,
                  params: { course_id: course.id, id: ms.id },
                  format: :js
        expect(subject).to respond_with(:success)
        expect { MarkingScheme.find(ms.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
