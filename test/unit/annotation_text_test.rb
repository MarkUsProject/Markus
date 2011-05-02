require File.join(File.dirname(__FILE__), '..', 'test_helper')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')
require 'shoulda'

class AnnotationTextTest < ActiveSupport::TestCase

  should belong_to :annotation_category
  should have_many :annotations

end
