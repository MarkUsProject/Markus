require 'faker'

FactoryBot.define do
  factory :note, class: Note do
    noteable_type { 'Grouping' }
    noteable { FactoryBot.create(:grouping) }
    role { FactoryBot.create(:instructor) }
    notes_message { Faker::Lorem.paragraphs[0] }
  end
end
