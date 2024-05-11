FactoryBot.define do
  factory :grade_entry_form do
    course { Course.first || association(:course) }
    sequence(:short_identifier) { |i| "Spreadsheet_#{i}" }
    description { Faker::Lorem.sentence }
    message { Faker::Lorem.sentence }
    due_date { Time.current }
    is_hidden { false }
    show_total { false }
  end

  factory :grade_entry_form_with_data, parent: :grade_entry_form do
    sequence(:short_identifier) { |i| "Spreadsheet_#{i}_with_data" }
    after(:create) do |grade_entry_form_with_data|
      item = create(:grade_entry_item, name: 'Test1', grade_entry_form: grade_entry_form_with_data)
      grade_entry_form_with_data.course.students.find_each do |student|
        ges = grade_entry_form_with_data.grade_entry_students.find_or_create_by(role: student)
        ges.grades.create(grade: Random.rand(item.out_of), grade_entry_item: item)
        ges.save
      end
    end
  end

  factory :grade_entry_form_with_data_and_total, parent: :grade_entry_form_with_data do
    sequence(:short_identifier) { |i| "Spreadsheet_#{i}_with_data_and_total" }
    show_total { true }
  end

  factory :grade_entry_form_with_multiple_grade_entry_items, parent: :grade_entry_form do
    sequence(:short_identifier) { |i| "Spreadsheet_#{i}_with_data" }
    after(:create) do |grade_entry_form_with_multiple_grade_entry_items|
      grade_entry_items = (1..3).map do |i|
        create(:grade_entry_item,
               grade_entry_form: grade_entry_form_with_multiple_grade_entry_items,
               out_of: 10, position: i)
      end
      grade_entry_form_with_multiple_grade_entry_items.grade_entry_items = grade_entry_items
    end
  end
end
