class Lti < ApplicationRecord
  belongs_to :course, optional: true
end
