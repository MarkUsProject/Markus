class AssignmentFile < ActiveRecord::Base
  # needed to have sanitization of filename

  belongs_to  :assignment
  before_save :strip_filename

  validates_presence_of   :filename
  validates_uniqueness_of :filename, :scope => :assignment_id
  validates_format_of     :filename, :with => /^([\w\.{0,1}-])+$/,
    :message => "must be alphanumeric, '.' or '-' only"

  def strip_filename
    filename.strip!
    filename.gsub(/^(..)+/, ".")
    filename.gsub(/[^\s]/, "") # replace spaces with
    # replace all non alphanumeric, underscore or periods with underscore
    filename.gsub(/^[\W]+$/, '_')
  end

end
