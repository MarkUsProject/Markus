# Context architecture
#
# - A section with no student associated to
# - A section with student associated to

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

require 'shoulda'

class SectionTest < ActiveSupport::TestCase

  should validate_presence_of :name
  should have_many :students

  context 'A section with no student associated to' do
    setup do
      @section = Section.make
    end

    context 'With a section due date for an assignment' do
      setup do
        @assignment = Assignment.make
        @section_due_date = SectionDueDate.make(section: @section,
                                                assignment: @assignment)
      end

      should 'return the section due date for an assignment' do
        assert_equal @section_due_date,
                     @section.section_due_date_for(@assignment)
      end
    end

    should 'return false to has_students?' do
      assert !@section.has_students?
    end

    should 'return 0 to count_student' do
      assert_equal 0, @section.count_students
    end
  end

  context 'A section with students associated to' do
    setup do
      @section = Section.make
      3.times { @section.students.make }
    end

    should 'return true to has_students?' do
      assert @section.has_students?
    end

    should 'return 3 to students associated to' do
      assert_equal 3, @section.count_students
    end
  end

end
