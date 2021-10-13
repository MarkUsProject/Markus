class Role < ApplicationRecord
  belongs_to :user
  belongs_to :course
  accepts_nested_attributes_for :user, allow_destroy: true
end
