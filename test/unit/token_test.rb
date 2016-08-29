require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class TokenTest < ActiveSupport::TestCase


  subject { @token }
  context 'valid Token' do
    setup do
      @token = Token.make
    end
    should validate_presence_of :remaining
    should validate_presence_of :grouping_id
    should 'be valid' do
      assert @token.valid?
    end
  end

  context 'valid Token' do
    setup do
      @token = Token.make(remaining: '0')
    end

    should 'be valid (tokens can be equal to 0)' do
      assert @token.valid?
    end
  end

  context 'function decrease_tokens' do
    context 'when number of tokens is greater than 0' do
      setup do
        @token = Token.make
        @token.decrease_tokens
      end

      should 'decrease number of tokens' do
        assert_equal(4, @token.remaining)
      end

      should 'update the token used date' do
        assert_equal(Time.now.strftime('%Y-%m-%d %H:%M'), @token.last_used.strftime('%Y-%m-%d %H:%M'))
      end
    end

    context 'when number of tokens is equal to 0' do
      setup do
        @token = Token.make(remaining: '0')
        @token.decrease_tokens
      end

      should 'not decrease number of tokens (not enough tokens)' do
        assert_equal(0, @token.remaining)
      end

      should 'not update the token used date' do
        assert_nil(@token.last_used)
      end
    end
  end

  context 'function reassign_tokens' do
    setup do
      @token = Token.make(remaining: '0')
      @token.grouping.assignment.token_start_date = 1.day.ago
      StudentMembership.make(
        grouping: @token.grouping,
        membership_status: StudentMembership::STATUSES[:inviter])
      StudentMembership.make(
        grouping: @token.grouping,
        membership_status: StudentMembership::STATUSES[:accepted])

      @token.reassign_tokens
    end
    should 'reassign assignment tokens' do
      assert_equal(10, @token.remaining)
    end
  end

  context 'function reassign_tokens' do
    setup do
      @token = Token.make(remaining: '2')
      a = @token.grouping.assignment
      a.tokens_per_period = 0
      a.save
      @token.reassign_tokens
    end
    should 'reassign assignment tokens (even if assignment.tokens is nil)' do
      assert_equal(0, @token.remaining)
    end
  end

  context 'update_tokens' do
    setup do
      @token = Token.make(remaining: '5')
    end
    should 'update token count properly when it is being increased' do
      @token.update_tokens(6, 9)
      assert_equal(8, @token.remaining)
    end
    should 'update token count properly when it is being decreased' do
      @token.update_tokens(6, 3)
      assert_equal(2, @token.remaining)
    end
    should 'not allow token count to go below 0' do
      @token.update_tokens(6, 0)
      assert_equal(0, @token.remaining)
    end
  end

  context 'Token' do
    setup do
      @token = Token.make{}
    end
    should 'be found' do
      assert_equal(@token, Token.find_by_grouping_id(@token.grouping_id))
    end
  end

  context 'Token' do
    setup do
      @token = Token.make
    end
    should 'not be found (wrong grouping_id)' do
      assert_nil(Token.find_by_grouping_id(0))
    end
  end
end
