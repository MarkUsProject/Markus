FactoryBot.define do
  factory :test_group do
    association :assignment
    sequence(:name) { |n| "Test Group #{n}" }
    sequence(:position) { |n| n }

    after :create do |test_group|
      test_group.update!(autotest_settings: { 'extra_info' => { 'test_group_id' => test_group.id } })
    end
  end
end
