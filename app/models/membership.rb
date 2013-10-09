# Join model representing a member in a grouping
class Membership < ActiveRecord::Base

  belongs_to :user
  belongs_to :grouping
  has_many :grace_period_deductions

  validates_presence_of   :user_id, :message => 'needs a user id'
  validates_associated    :user,    :message => 'associated user needs to be valid'

  validates_presence_of   :grouping_id, :message => 'needs a grouping id'
  validates_associated    :grouping,    :message => 'associated grouping needs to be valid'

end
