require 'faker'

FactoryBot.define do
  factory :note, class: Note do
    noteable_type { 'Grouping' }
    noteable { create(:grouping) }
    role { create(:instructor) }
    notes_message { Faker::Lorem.paragraphs[0] }
  end
end
