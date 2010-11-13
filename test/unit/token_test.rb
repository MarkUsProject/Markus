require File.dirname(__FILE__) + '/../test_helper'
require File.join(File.dirname(__FILE__),'/../blueprints/blueprints')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')
require 'shoulda'

class TokenTest < ActiveSupport::TestCase

  def setup
    clear_fixtures
  end

  def teardown
    
  end

  subject { @token }
  context "valid Token" do
    setup do
      @token = Token.make
    end
    should validate_presence_of :tokens
    should validate_presence_of :grouping_id
    should "be valid" do
      assert @token.valid?
    end
  end
  
  context "valid Token" do
    setup do
       @token = Token.make(:tokens => '0')
    end
    
    should "be valid (tokens can be equal to 0)" do
      assert @token.valid?
    end
  end
   
  context "function decrease_tokens" do
    context "when number of tokens is greater than 0" do
      setup do
         @token = Token.make
         @token.decrease_tokens
      end

      should "decrease number of tokens" do
        assert_equal(4, @token.tokens)
      end
    end

    context "when number of tokens is equal to 0" do
      setup do
         @token = Token.make(:tokens => '0')
         @token.decrease_tokens
      end

      should "not decrease numbre of tokens (not enough tokens)" do
        assert_equal(0, @token.tokens)
      end
    end
  end

  context "function reassign_tokens" do
    setup do
       @token = Token.make(:tokens => '0')
       @token.reassign_tokens
    end
    should "reassign assignment tokens" do
      assert_equal(10, @token.tokens)
    end
  end

  context "function reassign_tokens" do
    setup do
      @token = Token.make(:tokens => '2')
      a = @token.grouping.assignment 
      a.tokens_per_day = nil
      a.save
      @token.reassign_tokens
    end
    should "reassign assignment tokens (even if assignment.tokens is nil)" do
      assert_equal(0, @token.tokens)
    end
  end

  context "update_tokens" do
    setup do
      @token = Token.make(:tokens => '5')
    end
    should "update token count properly when it is being increased" do
      @token.update_tokens(6, 9)
      assert_equal(8, @token.tokens)
    end
    should "update token count properly when it is being decreased" do
      @token.update_tokens(6, 3)
      assert_equal(2, @token.tokens)
    end
    should "not allow token count to go below 0" do
      @token.update_tokens(6, 0)
      assert_equal(0, @token.tokens)
    end
  end

  context "Token" do
    setup do
      @token = Token.make{}
    end
    should "be found" do
      assert_equal(@token, Token.find_by_grouping_id(@token.grouping_id))
    end
  end

  context "Token" do
    setup do
      @token = Token.make
    end
    should "not be found (wrong grouping_id)" do
      assert_nil(Token.find_by_grouping_id(0))
    end
  end
end
