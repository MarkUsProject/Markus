namespace :db do

  desc 'Create Rubric for assignments'
  task :rubric => :environment do
    puts 'Add Rubric To Assignments'
    require 'faker'
    I18n.reload!

    def pos_rand(range)
      rand(range) + 1
    end

    def random_words(range)
      Faker::Lorem.words(number: pos_rand(range)).join(' ')
    end

    def random_sentences(range)
      Faker::Lorem.sentence(word_count: pos_rand(range))
    end

    Assignment.all.each do |assignment|
      5.times do |index|
        ac = AnnotationCategory.create(assignment: assignment,
                                       position: index + 1,
                                       annotation_category_name: random_words(3))

        (rand(10) + 3).times do
          AnnotationText.create(annotation_category: ac, content: random_sentences(3), creator: Admin.first)
        end
      end

      3.times do |index|
        attributes = []
        5.times do |number|
          lvl = { name: random_words(1), description: random_sentences(5), mark: number }
          attributes.push(lvl)
        end

        RubricCriterion.create!(
          name: random_sentences(1), assessment_id: assignment.id,
          position: index + 1, max_mark: 4, levels_attributes: attributes
        )
      end

      3.times do |index|
        FlexibleCriterion.create(
            name:                    random_sentences(1),
            assessment_id:           assignment.id,
            description:             random_sentences(5),
            position:                index + 4,
            max_mark:                pos_rand(3),
            created_at:              nil,
            updated_at:              nil,
            assigned_groups_count:   nil
        )
      end
      ac_with_criterion = AnnotationCategory.create(assignment: assignment,
                                                    position: 6,
                                                    annotation_category_name: random_words(1),
                                                    flexible_criterion_id: assignment.flexible_criteria.first.id)
      rand(3..12).times do |index|
        AnnotationText.create(annotation_category: ac_with_criterion,
                              content: random_sentences(3),
                              deduction: assignment.flexible_criteria.first.max_mark,
                              creator: Admin.first)
      end
      other_ac_with_criterion = AnnotationCategory.create(assignment: assignment,
                                                          position: 7,
                                                          annotation_category_name: random_words(1),
                                                          flexible_criterion_id: assignment.flexible_criteria.second.id)
      rand(3..12).times do |index|
        AnnotationText.create(annotation_category: other_ac_with_criterion,
                              content: random_sentences(2),
                              deduction: assignment.flexible_criteria.second.max_mark,
                              creator: Admin.first)
      end

      3.times do |index|
        CheckboxCriterion.create(
            name:                    random_sentences(1),
            assessment_id:           assignment.id,
            description:             random_sentences(5),
            position:                index + 7,
            max_mark:                1,
            created_at:              nil,
            updated_at:              nil,
            assigned_groups_count:   nil
        )
      end
    end
  end
end
