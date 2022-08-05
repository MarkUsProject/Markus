namespace :db do
  desc 'Update fake weights for scheme'
  task marking_scheme: :environment do
    puts 'Add Weights To Marking Scheme'

    marking_scheme = MarkingScheme.create(
      name: 'Scheme A'
    )

    # for each assessment, add a marking weight to marking_scheme
    Assessment.find_each do |a|
      random_weight = rand(1..10)
      marking_scheme.marking_weights << MarkingWeight.new(
        assessment_id: a.id, weight: random_weight
      )
    end
  end
end
