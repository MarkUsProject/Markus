class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  private

  # Checks that a record and its belongs_to associations are all associated with the same course
  def courses_should_match
    associations = self.class.reflect_on_all_associations(:belongs_to).map do |reflection|
      self.public_send(reflection.name)
    end
    associations << self
    course_ids = associations.filter_map { |a| a.is_a?(Course) ? a.id : a&.course&.id }
    if course_ids.to_set.length > 1
      names = associations.compact.map { |a| a.class.name.underscore }.join(', ')
      errors.add(:base, :courses_should_match, names: names)
    end
  end
end
