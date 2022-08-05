FactoryBot.define do
  factory :admin_role, class: AdminRole, parent: :role do
    user { association(:admin_user) }
  end
end
