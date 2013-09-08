require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class ResultTest < ActiveSupport::TestCase

  should have_many :marks
  should have_many :extra_marks
  should validate_presence_of :marking_state

  context 'A result with partial state' do
    setup do
      @result = Result.make(:marking_state => 'partial')
    end

    should 'get subtotal' do
      Mark.make(:result => @result)
      Mark.make(:result => @result)
      assert_equal(2, @result.get_subtotal, 'Subtotal should be equal to 2')
    end

    should 'catch a valid result (for partial marking state)' do
      assert @result.valid?
    end
  end

  context ' result in complete state' do
    setup do
      @result = Result.make(:marking_state => 'complete')
    end

    should 'mark as partial' do
      @result.mark_as_partial
      assert_equal(Result::MARKING_STATES[:partial],
                   @result.marking_state,
                   'marking state should be partial')
    end
  end

  context 'A released result' do
    setup do
      @result = Result.make(:marking_state => 'complete',
                            :released_to_students => true)
    end

    should 'catch a valid result (for complete marking state)' do
      assert @result.valid?
    end


    should 'unrelease results' do
      @result.unrelease_results
      assert(!@result.released_to_students, 'result should be unreleased')
    end
  end

#  def test_mark_as_partial2
#    # ???
#    result = Result.make(:marking_state => 'complete',
#                         :released_to_students => true)
#
#    # result.mark_as_complete
#    assert_equal(Result::MARKING_STATES[:complete], result.marking_state, "marking state should
#    be complete")
#  end

  should 'catch a valid result (for unmarked marking state)' do
      result = Result.make(:marking_state => 'unmarked')
      assert result.valid?
  end

  should 'catch a invalid result (wrong marking state)' do
      result = Result.make
      result.marking_state = 'wrong'
      assert result.invalid?
  end
end
