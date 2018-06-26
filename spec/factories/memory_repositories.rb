FactoryBot.define do
  factory :memory_repository, class: MemoryRepository do
    location { Faker::Name.first_name }
    initialize_with do
      new(location)
    end
  end
end
