# Context architecture
#
# TODO: Complete contexts
#
# - Tests on database structure and model
# - User Creation validations

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class UserTest < ActiveSupport::TestCase

  should have_many(:memberships)
  should have_many(:groupings).through(:memberships)
  should have_many(:notes).dependent(:destroy)
  should have_many(:accepted_memberships)
  should validate_presence_of :user_name
  should validate_presence_of :last_name
  should validate_presence_of :first_name
  should allow_value('Student').for(:type)
  should allow_value('Admin').for(:type)
  should allow_value('Ta').for(:type)
  should_not allow_value('OtherTypeOfUser').for(:type)


  context 'A good User model' do
    setup do
      # Any users will do
      Student.make
    end

    should validate_uniqueness_of :user_name

  end

  # test if user_name, last_name, first_name are stripped correctly
  context 'User creation validations' do
    setup do
      @unspaceduser_name = 'ausername'
      @unspacedfirst_name = 'afirstname'
      @unspacedlast_name = 'alastname'
      new_user = {
        :user_name => '   ausername   ',
        :last_name => '   alastname  ',
        :first_name => '   afirstname ',
        :type => 'Student'
      }
      @user = Student.new(new_user)

    end

    should 'strip all strings with white space' do
      assert @user.save
      assert_nil User.find_by_user_name('   ausername   ')
      assert_equal @user.user_name, @unspaceduser_name
      assert_equal @user.first_name, @unspacedfirst_name
      assert_equal @user.last_name, @unspacedlast_name
    end
  end

end
