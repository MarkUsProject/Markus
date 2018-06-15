class CriterionTaAssociation < ApplicationRecord

  belongs_to              :ta
  validates_associated    :ta

  belongs_to              :criterion, polymorphic: true
  validates_presence_of   :criterion_type
  validates_associated    :criterion

  belongs_to              :assignment

  before_validation       :add_assignment_reference, on: :create

  def add_assignment_reference
    self.assignment = criterion.assignment
  end

end
