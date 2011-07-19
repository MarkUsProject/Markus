require 'faker'

8.times do |time|
  rc = RubricCriterion.create(
        :id => time,
        :rubric_criterion_name => Faker::Lorem.sentence(1),
        :assignment_id => 1,
        :position => 1,
        :weight => rand(3) + 1,
        :level_0_name => Faker::Lorem.words(rand(5) + 1).join(" "),
        :level_0_description => Faker::Lorem.sentences(rand(5) + 1).join(" "),
        :level_1_name => Faker::Lorem.words(rand(5) + 1).join(" "),
        :level_1_description => Faker::Lorem.sentences(rand(5) + 1).join(" "),
        :level_2_name => Faker::Lorem.words(rand(5) + 1).join(" "),
        :level_2_description => Faker::Lorem.sentences(rand(5) + 1).join(" "),
        :level_3_name => Faker::Lorem.words(rand(5) + 1).join(" "),
        :level_3_description => Faker::Lorem.sentences(rand(5) + 1).join(" "),
        :level_4_name => Faker::Lorem.words(rand(5) + 1).join(" "),
        :level_4_description => Faker::Lorem.sentences(rand(5) + 1).join(" ")
    )
  rc.save
end

