class CriterionTaAssociation < ActiveRecord::Base

  belongs_to :ta
  belongs_to :criterion, :polymorphic => true
  belongs_to :assignment

  validates_presence_of   :ta_id
  validates_associated    :ta

  validates_presence_of   :criterion_id
  validates_presence_of   :criterion_type
  validates_associated    :criterion

  validates_presence_of   :assignment_id

  before_validation_on_create :add_assignment_reference

  def add_assignment_reference
    self.assignment = criterion.assignment
  end
end