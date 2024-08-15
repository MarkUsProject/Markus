FactoryBot.define do
  factory :admin_role, class: 'AdminRole', parent: :role do
    association :user, factory: :admin_user
  end
end
