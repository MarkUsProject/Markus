FactoryBot.define do
  factory :student, class: 'Student', parent: :role do
    grace_credits { 5 }
    receives_results_emails { true }
    receives_invite_emails { true }
  end
end
