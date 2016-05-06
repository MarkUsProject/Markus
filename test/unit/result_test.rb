require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class ResultTest < ActiveSupport::TestCase

  should have_many :marks
  should have_many :extra_marks
  should validate_presence_of :marking_state

  context 'A result with an incomplete state' do
    setup do
      @result = Result.make(marking_state: 'incomplete')
    end

    should 'get subtotal' do
      Mark.make(:result => @result)
      Mark.make(:result => @result)
      assert_equal(2, @result.get_subtotal, 'Subtotal should be equal to 2')
    end

    should 'catch a valid result (for incomplete marking state)' do
      assert @result.valid?
    end
  end

  context ' result in complete state' do
    setup do
      @result = Result.make(:marking_state => 'complete')
    end

    should 'mark as incomplete' do
      @result.mark_as_partial
      assert_equal(Result::MARKING_STATES[:incomplete],
                   @result.marking_state,
                   'marking state should be incomplete')
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

  should 'catch a valid result (for unmarked marking state)' do
      result = Result.make(marking_state: 'incomplete')
      assert result.valid?
  end

  should 'catch a invalid result (wrong marking state)' do
      result = Result.make
      result.marking_state = 'wrong'
      assert result.invalid?
  end
end
