class TestScript < ActiveRecord::Base
  has_many :test_results
  has_one :assignment
end
