# Class describing a course
class Course < ApplicationRecord
  attribute :is_hidden, :boolean, default: true
  validates_presence_of :name
  validates_uniqueness_of :name
  validates :name, format: { with: /\A[a-zA-Z0-9\-_]+\z/,
                             message: 'name must only contain alphanumeric, hyphen, or '\
                                      'underscore' }
  validates_presence_of :is_hidden
  validates :display_name, format: { with: /\A[a-zA-Z0-9\-_ ]+\z/,
                                     message: 'name must only contain alphanumeric, hyphen, '\
                                              'space, or underscore' }
end
