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

    context "on index" do
      setup do
        get_as @student, :index
      end

      should respond_with :missing

    end

    context "on create new section" do
      setup do
        get_as @student, :create_section
      end

      should respond_with :missing
    end

    context "on update new section" do
      setup do
        get_as @student, :update_section
      end

      should respond_with :missing
    end
  end

  context "A logged Admin" do
    setup do
      @admin = Admin.make
    end

    context "on index" do
      setup do
        get_as @admin, :index
      end

      should respond_with :success
    end

    context "on create_section" do
      setup do
        get_as @admin, :create_section
      end

      should respond_with :success
    end

    context "creating a section" do
      setup do
        post_as @admin, :create_section, {:section => {:name => "section_01"}}
      end

      should respond_with :redirect
      should set_the_flash.to(I18n.t('section.create.success'))

      should "add a section name section_01" do
        assert Section.find_by_name("section_01")
      end
    end

    context "tries to create a section with the same name as a existing one" do
      setup do
        section = Section.make
        post_as @admin, :create_section, {:section => {:name => section.name}}
      end

      should respond_with :success
      should set_the_flash.to(I18n.t('section.create.error'))

    end

    context "edits a section" do
      setup do
        section = Section.make
        get_as @admin, :edit_section, :id => section.id
      end

      should respond_with :success
    end

    context "edits a section name to 'nosection'" do
      setup do
        @section = Section.make
        post_as @admin, :edit_section, {:id => @section.id,
          :section => {:name => "no section"}}
      end

      should respond_with :redirect
      should set_the_flash.to(I18n.t('section.update.success'))

      should "have updated the name" do
        assert_not_nil Section.find_by_name("no section")
      end
    end
  end

end
