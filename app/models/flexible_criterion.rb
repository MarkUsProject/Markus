class FlexibleCriterion < ActiveRecord::Base
    set_table_name "flexible_criteria" # set table name correctly
    belongs_to  :assignment
# Not yet functional
#    has_many :marks
    validates_associated :assignment, :message => 'association is not strong with an assignment'
    validates_uniqueness_of :flexible_criterion_name, :scope => :assignment_id, :message => 'is already taken'
    validates_presence_of :flexible_criterion_name, :assignment_id, :max
    validates_numericality_of :assignment_id, :only_integer => true, :greater_than => 0, :message => "can only be whole number greater than 0"
    validates_numericality_of :max, :message => "must be a number greater than 0.0", :greater_than => 0.0
end
