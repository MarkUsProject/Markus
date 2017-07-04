namespace :db do
  desc 'Update fake weights for scheme'
  task :marking_scheme => :environment do
    puts 'Add Weights To Marking Scheme'

    marking_scheme = MarkingScheme.create(
      name: 'Scheme A'
    )

    #for each assignment, add a marking weight to marking_scheme
    Assignment.find_each do |a|
      random_weight = 1 + rand(0...10)
      marking_scheme.marking_weights << MarkingWeight.new(
        gradable_item_id: a.id, weight: random_weight, is_assignment: true)
    end

    GradeEntryForm.find_each do |grade_entry_form|
      random_weight = 1 + rand(0...10)
      marking_scheme.marking_weights << MarkingWeight.new(
        gradable_item_id: grade_entry_form.id, weight: random_weight, is_assignment: false)
    end
  end
end
