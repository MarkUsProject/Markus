require 'faker'

FactoryBot.define do
  factory :group do
    course { Course.order(:id).first || association(:course) }
    sequence(:group_name) { |n| "group#{n}" }

    after(:create) do |group|
      if group.repo_name.nil?
        group.repo_name = "group_#{group.id.to_s.rjust(4, '0')}"
        group.save
      end
    end
  end
end
