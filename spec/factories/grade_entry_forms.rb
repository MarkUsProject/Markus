FactoryBot.define do
  factory :grade_entry_form do
    sequence(:short_identifier) { |i| "Spreadsheet #{i}" }
    date { Time.now }
    is_hidden { false }
    show_total { false }
  end

  factory :grade_entry_form_with_data, class: GradeEntryForm do
    sequence(:short_identifier) { |i| "Spreadsheet #{i} (with data)" }
    date { Time.now }
    is_hidden { false }
    show_total { false }
    after(:create) do |grade_entry_form_with_data|
      create(:grade_entry_item, grade_entry_form: grade_entry_form_with_data)
    end
  end

  factory :grade_entry_form_with_data_and_total, class: GradeEntryForm do
    sequence(:short_identifier) { |i| "Spreadsheet #{i} (with data and total)" }
    date { Time.now }
    is_hidden { false }
    show_total { true }
    after(:create) do |grade_entry_form_with_data|
      create(:grade_entry_item, grade_entry_form: grade_entry_form_with_data)
    end
  end
end
