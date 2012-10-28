class TestScript < ActiveRecord::Base
  validates :seq_num, :presence => true
  validates :script_name, :presence => true

end
