class TestScript < ActiveRecord::Base
  has_many :test_runs
  has_one :assignment
end
