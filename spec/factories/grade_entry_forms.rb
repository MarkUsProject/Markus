FactoryGirl.define do
  factory :grade_entry_form do
    sequence(:short_identifier) { |i| "Spreadsheet#{i}" }
    date { Time.now }
  end

  factory :grade_entry_form_with_data, class: GradeEntryForm do
    sequence(:short_identifier) { |i| "M#{i}" }
    date { Time.now }
    after(:create) do |grade_entry_form_with_data|
      create(:grade_entry_student, grade_entry_form: grade_entry_form_with_data)
      #create(:grade_entry_item, grade_entry_form: grade_entry_form_with_data)
      #create(:another_grade_entry_item, grade_entry_form: grade_entry_form_with_data)
    end
  end
end
