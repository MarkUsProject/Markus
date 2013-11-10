class AnnotationText < ActiveRecord::Base

  belongs_to :annotation_category
  belongs_to :user, :foreign_key => :creator_id
  # An AnnotationText has many Annotations that are destroyed when an
  # AnnotationText is destroyed.
  has_many :annotations, :dependent => :destroy
  validates_associated   :annotation_category,
                         :message => 'annotation_category associations failed'
  
  #Find creator, return nil if not found
  def get_creator
    user =  User.find_by_id(creator_id)
  end

  #Find last user to update this text, nil if not found
  def get_last_editor
    editor = User.find_by_id(last_editor_id)
  end
end
