require 'faker'

FactoryBot.define do
  factory :note, class: 'Note' do
    noteable_type { 'Grouping' }
    association :noteable, factory: :grouping
    association :role, factory: :instructor
    notes_message { Faker::Lorem.paragraphs[0] }
  end
end
