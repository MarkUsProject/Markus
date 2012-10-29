class TestResult < ActiveRecord::Base
  belongs_to :submission

  validates_presence_of :submission # we require an associated submission
  validates_associated :submission # submission need to be valid
end
