FactoryBot.define do
  factory :grade_entry_form do
    sequence(:short_identifier) { |i| "Spreadsheet #{i}" }
    description { Faker::Lorem.sentence }
    message { Faker::Lorem.sentence }
    due_date { Time.now }
    is_hidden { false }
    show_total { false }
  end

  factory :grade_entry_form_with_data, class: GradeEntryForm do
    sequence(:short_identifier) { |i| "Spreadsheet #{i} (with data)" }
    description { Faker::Lorem.sentence }
    message { Faker::Lorem.sentence }
    due_date { Time.now }
    is_hidden { false }
    show_total { false }
    after(:create) do |grade_entry_form_with_data|
      item = create(:grade_entry_item, name: 'Test1', grade_entry_form: grade_entry_form_with_data)
      Student.find_each do |student|
        ges = grade_entry_form_with_data.grade_entry_students.find_or_create_by(user: student)
        ges.grades.create(grade: Random.rand(item.out_of), grade_entry_item: item)
        ges.save
      end
    end
  end

  factory :grade_entry_form_with_data_and_total, class: GradeEntryForm do
    sequence(:short_identifier) { |i| "Spreadsheet #{i} (with data and total)" }
    description { Faker::Lorem.sentence }
    message { Faker::Lorem.sentence }
    due_date { Time.now }
    is_hidden { false }
    show_total { true }
    after(:create) do |grade_entry_form_with_data|
      create(:grade_entry_item, grade_entry_form: grade_entry_form_with_data)
    end
  end
end
