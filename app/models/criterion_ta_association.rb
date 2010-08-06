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

  before_validation :add_assignment_reference

  before_create     :set_previously_assigned_groups
  after_create      :increment_criteria_coverage
  after_destroy     :decrement_criteria_coverage

  def add_assignment_reference
    self.assignment = criterion.assignment
  end

  def set_previously_assigned_groups
    @previously_assigned_groups =criterion.all_assigned_groups
  end

  #could do this in the same way as decrement... better??
  def increment_criteria_coverage
    ta.memberships_for_assignment(assignment).each do |membership|
      grouping = membership.grouping
      if !@previously_assigned_groups.include? grouping
        grouping.criteria_coverage_count += 1
      end
      grouping.save
    end
  end
  
  def decrement_criteria_coverage
    ta.memberships_for_assignment(assignment).each do |membership|
      grouping = membership.grouping
      if grouping.assigned_tas_for_criterion(self).size == 0
        grouping.criteria_coverage_count -= 1
      end
      grouping.save
    end
  end

end