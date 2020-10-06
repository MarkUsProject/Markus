FactoryBot.define do
  factory :test_student, class: TestStudent, parent: :user do
    hidden { true }
  end
end
