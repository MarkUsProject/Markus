class TestRun < ActiveRecord::Base
  has_one :test_scripts
  has_one :group
end
