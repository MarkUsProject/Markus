class Tag < ActiveRecord::Base
  # Sets up what the tag itself belongs to.
  belongs_to :user, foreign_key: :creator_id

  # Sets its connection with the assignment model.
  has_many :assignments, through: :taggings

  # Function for getting the creator of the tag.
  def get_creator
    User.find_by_id(creator_id);
  end

  # Function for getting the last user of the tag.
  def get_last_user
    User.find_by_id(luser_id)
  end
end