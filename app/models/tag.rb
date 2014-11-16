class Tag < ActiveRecord::Base

  has_and_belongs_to_many :groupings

  def == (another_tag)
    self.description == another_tag.description &&
        self.name == another_tag.name
  end
end
