class Description < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :category
  
  validates_presence_of :name, :description, :token, :ntoken, :category_id, :assignment_id
  
  validates_associated      :assignment, :message => 'assignment associations failed'
  validates_associated      :category, :message => 'category associations failed'
  
  validates_numericality_of :category_id, :only_integer => true, :greater_than => 0, :message => 'can only be whole number greater than 0.'
  validates_numericality_of :assignment_id, :only_integer => true, :greater_than => 0, :message => 'can only be whole number greater than 0.'
end
