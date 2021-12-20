FactoryBot.define do
  factory :template_division do
    association :exam_template, factory: :exam_template_midterm
    association :assignment_file
    start { 1 }
    self.send('end') { 1 }
    label { 'section' }
  end
end
