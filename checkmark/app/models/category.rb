class Category < ActiveRecord::Base
  validates_presence_of :name, :token, :ntoken
end
