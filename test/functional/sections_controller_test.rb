# Using machinist

require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__),'..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__),'..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__),'..', 'blueprints', 'helper'))
require 'shoulda'


class SectionsControllerTest < AuthenticatedControllerTest

  context 'A logged student' do
    setup do
      @student = Student.make
    end

    should 'on index' do
      get_as @student, :index
      assert_response :missing
    end

    should 'on create new section' do
      post_as @student, :create
      assert_response :missing
    end

    should 'on edit section' do
      get_as @student, :edit, id: Section.make.id
      assert respond_with :missing
    end

    should 'on update new section' do
      put_as @student, :update, id: Section.make.id
      assert_response :missing
    end

    should 'not be able to delete a section' do
      section = Section.make
      delete_as @student, :destroy, id: section
      assert respond_with :missing
      assert_not_nil Section.find(section.id)
    end
  end

  context 'A logged Admin' do
    setup do
      @admin = Admin.make
    end

    should 'on index' do
      get_as @admin, :index
      assert_response :success
    end

    should 'creating a section' do
      post_as @admin, :create, {section: {name: 'section_01'}}

      assert_response :redirect
      assert_equal flash[:success], [I18n.t('section.create.success', name: 'section_01')]
      assert Section.find_by_name('section_01')
    end

   should 'not be able to create a section with the same name as a existing one' do
      section = Section.make
      post_as @admin, :create, {section: {name: section.name}}
      assert_response :success
      assert_equal flash[:error],
                   [I18n.t('section.create.error')]
    end

    should 'not be able to create a section with a blank name' do
      section = Section.make
      post_as @admin, :create, {section: {name: ''}}
      assert respond_with :success
      assert_nil Section.find_by_name('')
      assert_response :success
      assert_equal flash[:error],
                   [I18n.t('section.create.error')]
    end

    should 'be able to edit a section' do
      section = Section.make
      get_as @admin, :edit, id: section.id
      assert_response :success
    end

    should "be able to update a section name to 'nosection'" do
      @section = Section.make
      put_as @admin,
              :update,
              id: @section.id,
              section: {name: 'no section'}

      assert_response :redirect
      assert_equal flash[:success], [I18n.t('section.update.success', name: 'no section')]

      assert_not_nil Section.find_by_name('no section')
    end

    should 'not see a table if no students in this section' do
      section = Section.make
      get_as @admin, :edit, id: section.id
      assert_nil response.body.to_s.match('section_students')
    end

    should 'see a table if the section has students in it' do
      section = Section.make
      student = Student.make
      section.students << student
      get_as @admin, :edit, id: section.id
      assert_not_nil response.body.to_s.match('section_students')
    end

    should 'not be able to edit a section name to an existing name' do
      @section = Section.make
      @section2 = Section.make
      put_as @admin,
              :update,
              id: @section.id,
              section: {name: @section2.name}
      assert_response :success
      assert_equal [I18n.t('section.update.error')], flash[:error]
    end

    context 'with an already created section' do
      setup do
        @section = Section.make
      end

      should 'be able to delete a section with no students' do
        assert_difference('Section.count', -1) do
          delete_as @admin, :destroy, id: @section.id
        end
        assert_equal [I18n.t('section.delete.success')], flash[:success]
      end

      should 'not be able to delete a section with students in it' do
        @student = Student.make
        @section.students << @student
        delete_as @admin, :destroy, id: @section.id
        assert_equal [I18n.t('section.delete.not_empty')], flash[:error]
        assert_not_nil Section.find(@section.id)
      end
    end
  end

end
