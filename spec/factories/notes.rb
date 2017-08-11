require 'faker'

FactoryGirl.define do
  factory :note, class: Note do
    noteable_type  {'Grouping'}
    noteable { FactoryGirl.create(:grouping) }
    user { FactoryGirl.create(:admin) }
    notes_message { Faker::Lorem.paragraphs[0] }
  end
end
