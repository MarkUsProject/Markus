require 'set'

class PeerReview < ActiveRecord::Base
  belongs_to :result
  belongs_to :reviewer, class_name: 'Grouping'

  validates_associated :reviewer
  validates_associated :result
  validates_presence_of :reviewer
  validates_presence_of :result
  validates_numericality_of :reviewer_id, only_integer: true, greater_than: 0
  validates_numericality_of :result_id, only_integer: true, greater_than: 0
  validate :no_students_should_be_reviewer_and_reviewee

  def reviewee
    # TODO - Research optimizing or see if rails can do better
    Grouping.joins({ submissions: { results: :peer_reviews }}).where('peer_reviews.id = ?', self.id).first
  end

  def no_students_should_be_reviewer_and_reviewee
    if result and reviewer
      student_id_set = Set.new
      reviewer.students.each { |student| student_id_set.add(student.id) }
      result.submission.grouping.students.each do |student|
        if student_id_set.include?(student.id)
          errors.add(:reviewer_id, I18n.t('peer_review.cannot_allow_reviewer_to_be_reviewee'))
          break
        end
      end
    end
  end
end
