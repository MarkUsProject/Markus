FactoryBot.define do
  factory :split_pdf_log do
    association :role, factory: :instructor
    association :exam_template, factory: :exam_template_midterm
    filename { 'midterm1-v2-test.pdf' }
    num_groups_in_complete { 0 }
    num_groups_in_incomplete { 0 }
    num_pages_qr_scan_error { 0 }
    original_num_pages { 0 }
  end
end
