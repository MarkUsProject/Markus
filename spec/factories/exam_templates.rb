FactoryBot.define do
  factory :exam_template_midterm, class: ExamTemplate do
    association :assignment, factory: :assignment_for_scanned_exam
    filename { 'midterm1-v2-test.pdf' }
    num_pages { 6 }

    after(:create) do |exam_template|
      exam_template.template_divisions.create(start: 3, end: 3, label: 'Q1')
      exam_template.template_divisions.create(start: 4, end: 4, label: 'Q2')
      exam_template.template_divisions.create(start: 5, end: 6, label: 'Q3')
    end
  end
end
