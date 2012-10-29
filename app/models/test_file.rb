class TestFile < ActiveRecord::Base
  validates :file_name, :presence => true
  validates :description, :presence => true
end
