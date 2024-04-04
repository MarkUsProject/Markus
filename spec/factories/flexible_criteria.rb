FactoryBot.define do
  factory :flexible_criterion do
    sequence(:name) { |n| "Flexible criterion #{n}" }
    association :assignment
    max_mark { 1.0 }
    ta_visible { true }
    peer_visible { false }
    sequence(:position)
  end

  factory :flexible_criterion_with_annotation_category, parent: :flexible_criterion do
    max_mark { 3.0 }
    after(:create) do |flexible_criterion|
      new_category = create(:annotation_category,
                            flexible_criterion_id: flexible_criterion.id,
                            assignment: flexible_criterion.assignment)
      create(:annotation_text_with_deduction, annotation_category: new_category)
    end
  end
end
