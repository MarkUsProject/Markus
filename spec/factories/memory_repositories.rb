require 'repo/memory_repository'

FactoryGirl.define do
  factory :memory_repository, class: Repository::MemoryRepository do
    location { Faker::Name.first_name }
    initialize_with do
      new(location)
    end
  end
end
