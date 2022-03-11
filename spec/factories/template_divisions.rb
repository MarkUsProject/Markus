FactoryBot.define do
  factory :template_division do
    association :exam_template, factory: :exam_template_midterm
    association :assignment_file
    start { 2 }
    add_attribute(:end) { 2 }
    label { 'section' }
  end
end
