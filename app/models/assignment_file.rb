class AssignmentFile < ActiveRecord::Base
  # needed to have sanitization of filename
  include SubmissionsHelper

  belongs_to  :assignment
  before_save :strip_filename

  validates_presence_of   :filename
  validates_uniqueness_of :filename, :scope => :assignment_id
  validates_format_of     :filename, :with => /^([\w\.{0,1}-])+$/,
    :message => "must be alphanumeric, '.' or '-' only"

  # sanitize filename input before saving
  # using the function in Submission Helper
  def strip_filename
    filename = sanitize_file_name(filename)
  end

end
