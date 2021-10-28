# Subclass of User for "Human" users (Admin, Student, TA)
class Human < User
  has_many :roles, inverse_of: :human
  validates_presence_of :roles, unless: -> { self.new_record? }
end
