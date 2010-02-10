# Tests with MACHINIST

require File.join(File.dirname(__FILE__),'/../test_helper')
require File.join(File.dirname(__FILE__),'/../blueprints/blueprints')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')
require 'shoulda'

class SectionTest < ActiveSupport::TestCase
  SHOW_GENERATED_DATA = false
  SHOW_DEPENDENCY_GENERATED_DATA = true

  should_validate_presence_of :name
  should_have_many :students

end



