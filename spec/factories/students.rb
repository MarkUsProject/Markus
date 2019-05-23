FactoryBot.define do
  factory :student, class: Student, parent: :user do
    grace_credits { 5 }
  end
end
