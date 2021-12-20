FactoryBot.define do
  factory :split_page do
    association :split_pdf_log
    association :group
    filename { 'midterm1-v2-test.pdf' }
    raw_page_number { 1 }
  end
end
