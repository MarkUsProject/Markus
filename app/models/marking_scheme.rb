class MarkingScheme < ActiveRecord::Base
  attr_accessible :name
  has_many :marking_weights, dependent: :destroy
  accepts_nested_attributes_for :marking_weights
end
