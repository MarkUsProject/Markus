FactoryBot.define do
  factory :test_group do
    association :assignment
    sequence(:name) { |n| "Test Group #{n}" }
    sequence(:position) { |n| n }
    criterion { nil }

    after :create do |test_group|
      test_group.update!(autotest_settings: {
        'extra_info' => { 'test_group_id' => test_group.id },
        'category' => []
      })
    end
  end

  factory :test_group_student_runnable, parent: :test_group do
    after :create do |test_group|
      test_group.update!(autotest_settings: { 'category' => ['student'] })
    end
  end
end
