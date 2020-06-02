describe MarkingSchemesController do

  let(:grade_entry_form) { create(:grade_entry_form) }
  let(:grade_entry_form_with_data) { create(:grade_entry_form_with_data) }
  let(:assignment) { create(:assignment) }
  let(:assignment_with_criteria_and_results) { create(:assignment_with_criteria_and_results) }

  context '#index' do
    it 'returns correct JSON data' do
      byebug
      marking_scheme = create(:marking_scheme, assessments: [assignment, assignment_with_criteria_and_results])
      p marking_scheme
    end
  end

  context '#populate' do

  end

  context '#create' do

  end

  context '#update' do

  end

  context '#new' do

  end

  context '#edit' do

  end

  context '#destroy' do

  end
end
