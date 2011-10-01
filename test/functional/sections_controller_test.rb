# Using machinist

require File.dirname(__FILE__) + '/authenticated_controller_test'
require File.join(File.dirname(__FILE__),'/../test_helper')
require File.join(File.dirname(__FILE__),'/../blueprints/blueprints')
require File.join(File.dirname(__FILE__),'/../blueprints/helper')
require 'shoulda'


class SectionsControllerTest < AuthenticatedControllerTest

  def setup
    clear_fixtures
  end

  context "A logged student" do
    setup do
      @student = Student.make
    end

    should "on index" do
      get_as @student, :index
      assert respond_with :missing
    end

    should "on create new section" do
      post_as @student, :create
      assert respond_with :missing
    end

    should "on update new section" do
      put_as @student, :update, :id => Section.make.id
      assert respond_with :missing
    end
  end

  context "A logged Admin" do
    setup do
      @admin = Admin.make
    end

    should "on index" do
      get_as @admin, :index
      assert respond_with :success
    end

    should "creating a section" do
      post_as @admin, :create, {:section => {:name => "section_01"}}

      assert respond_with :redirect
      assert set_the_flash.to(I18n.t('section.create.success'))
      assert Section.find_by_name("section_01")
    end

   should "tries to create a section with the same name as a existing one" do
      section = Section.make
      post_as @admin, :create, {:section => {:name => section.name}}
      assert respond_with :success
      assert_equal flash[:error], I18n.t('section.create.error') + ' Name has already been taken.'
    end

    should "tries to create a section with a blank name" do
      section = Section.make
      post_as @admin, :create, {:section => {:name => ''}}
      assert respond_with :success
      assert_equal flash[:error], I18n.t('section.create.error') + ' Name can\'t be blank.'
    end

    should "edits a section" do
      section = Section.make
      get_as @admin, :edit, :id => section.id
      assert respond_with :success
    end

    should "edits a section name to 'nosection'" do
      @section = Section.make
      put_as @admin,
              :update,
              :id => @section.id,
              :section => {:name => "no section"}

      assert respond_with :redirect
      assert set_the_flash.to(I18n.t('section.update.success'))

      assert_not_nil Section.find_by_name("no section")
    end

    should "edits a section name to an existing name" do
      @section = Section.make
      @section2 = Section.make
      put_as @admin,
              :update,
              :id => @section.id,
              :section => {:name => @section2.name}
      assert_response :redirect
      assert_equal flash[:error], I18n.t('section.update.error') + ' Name has already been taken.'
    end
  end

end
