FactoryBot.define do
  factory :exam_template_midterm, class: 'ExamTemplate' do
    association :assignment, factory: :assignment_for_scanned_exam
    filename { 'midterm1-v2-test.pdf' }
    num_pages { 6 }

    after(:create) do |exam_template|
      exam_template.template_divisions.create(start: 3, end: 3, label: 'Q1')
      exam_template.template_divisions.create(start: 4, end: 4, label: 'Q2')
      exam_template.template_divisions.create(start: 5, end: 6, label: 'Q3')
    end
  end

  factory :exam_template_with_automatic_parsing, parent: :exam_template_midterm do
    automatic_parsing { true }
    cover_fields { 'id_number' }
    crop_x { 0.2925 }
    crop_y { 0.4216 }
    crop_width { 0.37 }
    crop_height { 0.0464 }
    filename { 'test-auto-parse.pdf' }
  end
end
