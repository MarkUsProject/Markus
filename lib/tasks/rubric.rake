namespace :db do
  desc 'Create Rubric for assignments'
  task rubric: :environment do
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

    names = Faker::Lorem.unique.words(number: 9)
    Assignment.find_each do |assignment|
      5.times do |index|
        ac = AnnotationCategory.create(assignment: assignment,
                                       position: index + 1,
                                       annotation_category_name: random_words(3))

        rand(3..12).times do
          AnnotationText.create(annotation_category: ac,
                                content: random_sentences(3),
                                creator: Instructor.first,
                                last_editor: Instructor.first)
        end
      end

      3.times do |index|
        attributes = []
        5.times do |number|
          lvl = { name: random_words(1), description: random_sentences(5), mark: number }
          attributes.push(lvl)
        end

        RubricCriterion.create!(
          name: names[index], assessment_id: assignment.id,
          position: index + 1, max_mark: 4, levels_attributes: attributes
        )
      end

      3.times do |index|
        FlexibleCriterion.create(
          name: names[3 + index],
          assessment_id: assignment.id,
          description: random_sentences(5),
          position: index + 4,
          max_mark: pos_rand(3)
        )
      end
      criterion = assignment.criteria.where(type: 'FlexibleCriterion').first
      ac_with_criterion = AnnotationCategory.create(assignment: assignment,
                                                    position: 6,
                                                    annotation_category_name: random_words(1),
                                                    flexible_criterion_id: criterion.id)
      rand(3..12).times do
        AnnotationText.create(annotation_category: ac_with_criterion,
                              content: random_sentences(3),
                              deduction: criterion.max_mark,
                              creator: Instructor.first,
                              last_editor: Instructor.first)
      end

      other_criterion = assignment.criteria.where(type: 'FlexibleCriterion').second
      other_ac_with_criterion = AnnotationCategory.create(assignment: assignment,
                                                          position: 7,
                                                          annotation_category_name: random_words(1),
                                                          flexible_criterion_id: other_criterion.id)
      rand(3..12).times do
        AnnotationText.create(annotation_category: other_ac_with_criterion,
                              content: random_sentences(2),
                              deduction: other_criterion.max_mark,
                              creator: Instructor.first,
                              last_editor: Instructor.first)
      end

      3.times do |index|
        CheckboxCriterion.create(
          name: names[6 + index],
          assessment_id: assignment.id,
          description: random_sentences(5),
          position: index + 7,
          max_mark: 1
        )
      end
    end
  end
end
