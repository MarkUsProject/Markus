require File.dirname(__FILE__) + '/test_helper.rb'
require 'test/unit'
require 'rubygems'
require 'mocha'

class User < ActiveRecord::Base
end

class Customer < ActiveRecord::Base
  set_primary_key "cust_id"
end

class DbPopulateTest < Test::Unit::TestCase
  
  def test_creates_new_record
    User.delete_all
    User.create_or_update(:id => 1, :name => "Fred")
    assert_equal User.count, 1
    u = User.find(:first)
    assert_equal u.name, "Fred"
  end
  
  def test_updates_existing_record
    User.delete_all
    User.create_or_update(:id => 1, :name => "Fred")
    User.create_or_update(:id => 1, :name => "George")
    assert_equal User.count, 1
    u = User.find(:first)
    assert_equal u.name, "George"
  end
  
  def test_creates_new_record_with_nonstandard_pk
    Customer.delete_all
    Customer.create_or_update(:cust_id => 1, :name => "Fred")
    assert_equal Customer.count, 1
    c = Customer.find(:first)
    assert_equal c.name, "Fred"
  end
  
  def test_updates_existing_record
    Customer.delete_all
    Customer.create_or_update(:cust_id => 1, :name => "Fred")
    Customer.create_or_update(:cust_id => 1, :name => "George")
    assert_equal Customer.count, 1
    c = Customer.find(:first)
    assert_equal c.name, "George"
  end
  
end

