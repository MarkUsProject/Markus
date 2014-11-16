class Tag < ActiveRecord::Base

  has_and_belongs_to_many :groupings

  def ==(another_tag)
    description == another_tag.description &&
        name == another_tag.name
  end
end
