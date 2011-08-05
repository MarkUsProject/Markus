require 'faker'

5.times do |time|
  ca = AnnotationCategory.new(
          :id => time,
          :assignment_id => 1,
          :annotation_category_name => Faker::Lorem.words(
                                           rand(3) + 1
                                         ).join(" ")
        )
  ca.save

  (rand(10) + 3).times do |t|
    a = AnnotationText.new(
            :id => t,
            :annotation_category_id => time,
            :content => Faker::Lorem.sentences(rand(3) + 1).join(" ")
          )
    a.save
  end
end


