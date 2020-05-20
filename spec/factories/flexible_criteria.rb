FactoryBot.define do
  factory :flexible_criterion do
    sequence(:name) { |n| "Flexible criterion #{n}" }
    association :assignment, factory: :assignment
    max_mark { 1.0 }
    ta_visible { true }
    peer_visible { false }
    sequence(:position)
  end

  factory :flexible_criterion_with_annotation_category, parent: :flexible_criterion do
    max_mark { 3.0 }
    after(:create) do |flexible_criterion|
      flexible_criterion.annotation_categories << create(:annotation_category,
                                                         flexible_criterion_id: flexible_criterion.id,
                                                         assignment: flexible_criterion.assignment)
      flexible_criterion.annotation_categories.first.annotation_texts << create(:annotation_text_with_deduction)
    end
  end
end
