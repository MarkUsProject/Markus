class CriterionTaAssociation < ApplicationRecord

  belongs_to              :ta
  validates_presence_of   :ta_id
  validates_associated    :ta

  belongs_to              :criterion, polymorphic: true
  validates_presence_of   :criterion_id
  validates_presence_of   :criterion_type
  validates_associated    :criterion

  belongs_to              :assignment
  validates_presence_of   :assignment_id

  before_validation       :add_assignment_reference, on: :create

  def add_assignment_reference
    self.assignment = criterion.assignment
  end

end
