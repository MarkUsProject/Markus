require 'faker'

FactoryBot.define do
  factory :note, class: Note do
    noteable_type  {'Grouping'}
    noteable { FactoryBot.create(:grouping) }
    user { FactoryBot.create(:admin) }
    notes_message { Faker::Lorem.paragraphs[0] }
  end
end
