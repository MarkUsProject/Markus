FactoryBot.define do
  factory :student, class: Student, parent: :user do
    grace_credits { 5 }
    receives_results_emails { true }
    receives_invite_emails { true }
  end
end
