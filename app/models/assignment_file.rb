class AssignmentFile < ActiveRecord::Base

  belongs_to  :assignment

  validates_presence_of   :filename
  validates_uniqueness_of :filename, :scope => :assignment_id
  validates_format_of     :filename, :with => /^([\w\.{0,1}-])+$/,
    :message => "must be alphanumeric, '.' or '-' only"

end
