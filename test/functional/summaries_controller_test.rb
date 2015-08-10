require File.expand_path(File.join(File.dirname(__FILE__),
                                   'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__),
                                   '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__),
                                   '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__),
                                   '..', 'blueprints', 'helper'))
require 'shoulda'

class SummariesControllerTest < AuthenticatedControllerTest
  context 'instructor attempts to display all information' do

    setup do
      @admin = Admin.make
      @group = Group.make
      @assignment = Assignment.make
      @grouping = Grouping.make(group: @group, assignment: @assignment)

    end

  end
end
