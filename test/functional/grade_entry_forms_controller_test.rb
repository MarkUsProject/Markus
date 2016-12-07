# encoding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class GradeEntryFormsControllerTest < AuthenticatedControllerTest

  # Constants for :edit tests
  NEW_SHORT_IDENTIFIER = 'NewSI'
  NEW_DESCRIPTION = 'NewDescription'
  NEW_MESSAGE = 'NewMessage'
  NEW_DATE = 3.days.from_now

  # An authenticated and authorized student
  context 'An authenticated and authorized student doing a ' do
    setup do
      @student = Student.make
      @grade_entry_form = GradeEntryForm.make
      @grade_entry_form_with_grade_entry_items = make_grade_entry_form_with_multiple_grade_entry_items
      @grade_entry_student = @grade_entry_form_with_grade_entry_items.grade_entry_students.find_by(user: @student)
      @grade_entry_form_with_grade_entry_items.grade_entry_items.each do |grade_entry_item|
        @grade_entry_student.grades.make(grade_entry_item: grade_entry_item, grade: 5)
      end
    end

    # Students are not allowed to create or edit grade entry form properties
    should 'GET on :new' do
      get_as @student, :new
      assert_response :missing
    end

    should 'GET on :edit' do
      get_as @student, :edit, id: 1
      assert_response :missing
    end

    should 'GET on :grades' do
      get_as @student, :grades, id: 1
      assert_response :missing
    end

    # Test that the students can access the student_interface
    should 'GET on :student_interface when no marks have been entered for this student' do
      get_as @student, :student_interface, id: @grade_entry_form.id
      assert_not_nil assigns :grade_entry_form
      assert_not_nil assigns :student
      assert render_template :student_interface
      assert_response :success
      assert_equal true, flash.empty?
      assert_match Regexp.new(I18n.t('grade_entry_forms.students.no_results')), @response.body
    end

    should "GET on :student_interface when marks have been entered for this student and have been released" do
      @grade_entry_form_with_grade_entry_items.show_total = true
      @grade_entry_form_with_grade_entry_items.save
      @grade_entry_student.released_to_student = true
      @grade_entry_student.save
      total = @grade_entry_form_with_grade_entry_items.out_of_total.to_i.to_s

      get_as @student, :student_interface, id: @grade_entry_form_with_grade_entry_items.id
      assert_not_nil assigns :grade_entry_form
      assert_not_nil assigns :student
      assert render_template :student_interface
      assert_response :success
      assert_equal true, flash.empty?
      assert_match Regexp.new(total), @response.body
    end

    should 'GET on :student_interface when marks have been entered for this student but have not been released' do
      get_as @student, :student_interface, id: @grade_entry_form_with_grade_entry_items.id
      assert_not_nil assigns :grade_entry_form
      assert_not_nil assigns :student
      assert render_template :student_interface
      assert_response :success
      assert_equal true, flash.empty?
      assert_match Regexp.new(I18n.t('grade_entry_forms.students.no_results')), @response.body
    end

    should "GET on :student_interface when the student's mark has been released and it is a blank mark" do
      student1 = Student.make
      grade_entry_student1 = @grade_entry_form_with_grade_entry_items.grade_entry_students.find_by(user: student1)
      grade_entry_student1.released_to_student = true
      grade_entry_student1.save
      get_as student1, :student_interface, id: @grade_entry_form_with_grade_entry_items.id
      assert_not_nil assigns :grade_entry_form
      assert_not_nil assigns :student
      assert render_template :student_interface
      assert_response :success
      assert_equal true, flash.empty?
    end

    should 'POST on :new' do
      post_as @student, :new
      assert_response :missing
    end

    should 'POST on :edit' do
      post_as @student, :edit, id: 1
      assert_response :missing
    end

    should 'POST on :grades' do
      post_as @student, :grades, id: 1
      assert_response :missing
    end

    should 'POST on :student_interface' do
      post_as @student, :student_interface, id: @grade_entry_form.id
      assert_not_nil assigns :grade_entry_form
      assert_not_nil assigns :student
      assert render_template :student_interface
      assert_response :success
      assert_equal true, flash.empty?
    end
  end

  # An authenitcated and authorized TA
  context 'An authenticated and authorized TA doing a ' do
    setup do
      @ta = Ta.make
    end

    # TAs are not allowed to create or edit grade entry form properties or access
    # the student interface
    should 'GET on :new' do
      get_as @ta, :new
      assert_response :missing
    end

    should 'GET on :edit' do
      get_as @ta, :edit, id: 1
      assert_response :missing
    end

    should 'GET on :student_interface' do
      get_as @ta, :student_interface, id: 1
      assert_response :missing
    end

    should 'POST on :new' do
      post_as @ta, :new
      assert_response :missing
    end

    should 'get on :edit' do
      get_as @ta, :edit, id: 1
      assert_response :missing
    end

    should 'POST on :student_interface' do
      post_as @ta, :student_interface
      assert_response :missing
    end
  end

  # An authenticated and authorized admin
  context 'An authenticated and authorized admin doing a ' do
    setup do
      @admin = Admin.make
      @grade_entry_form = GradeEntryForm.make
      @grade_entry_form_with_grade_entry_items = make_grade_entry_form_with_multiple_grade_entry_items
      @original = @grade_entry_form
      @original_with_grade_entry_items = @grade_entry_form_with_grade_entry_items
      10.times {Student.make}
    end

    should 'GET on :new' do
      get_as @admin, :new
      assert_not_nil assigns :grade_entry_form
      assert render_template :new
      assert_response :success
      assert_equal true, flash.empty?
    end

    should 'GET on :edit' do
      get_as @admin, :edit, id: @grade_entry_form.id
      assert_not_nil assigns :grade_entry_form
      assert render_template :edit
      assert_response :success
      assert_equal true, flash.empty?
    end

    should 'GET on :student_interface' do
      get_as @admin, :student_interface
      assert_response :missing
    end

    should 'GET on :grades when there are no grade entry items' do
      get_as @admin, :grades, id: @grade_entry_form.id
      assert_not_nil assigns :grade_entry_form
      assert render_template :grades
      assert_response :success
      assert_match Regexp.new(I18n.t('grade_entry_forms.grades.no_grade_entry_items_message')), @response.body
    end

    should 'GET on :grades when there are grade entry items' do
      get_as @admin, :grades, id: @grade_entry_form_with_grade_entry_items.id
      assert_not_nil assigns :grade_entry_form
      assert render_template :grades
      assert_response :success
    end

    should 'POST on :student_interface' do
      post_as @admin, :student_interface
      assert_response :missing
    end

    # Test valid and invalid values for basic properties for :new
    should 'create with basic valid properties' do
      post_as @admin,
              :create,
              {grade_entry_form: {
                    short_identifier: 'NT',
                    description: @grade_entry_form.description,
                    message: @grade_entry_form.message,
                    date: @grade_entry_form.date,
                    is_hidden: @grade_entry_form.is_hidden } }
      assert_not_nil assigns :grade_entry_form
      assert_equal flash[:success], [I18n.t('grade_entry_forms.create.success')]
      assert_response :redirect
    end

    should ' not be able to create with a missing required value' do
      post_as @admin,
              :create,
              {grade_entry_form: {
                      short_identifier: '',
                      description: @grade_entry_form.description,
                      message: @grade_entry_form.message,
                      date: @grade_entry_form.date}}
      assert_not_nil assigns :grade_entry_form
      assert_nil flash[:error]
      assert_equal assigns(:grade_entry_form).errors[:short_identifier][0], I18n.t('grade_entry_forms.blank_field')
      assert_response :ok
    end

    should 'POST on :create with an invalid basic value' do
      post_as @admin,
              :create,
              grade_entry_form: {
                  short_identifier: 'NT',
                  description: @grade_entry_form.description,
                  message: @grade_entry_form.message,
                  date: 'abcd'}
      assert_not_nil assigns :grade_entry_form
      assert_nil flash[:error]
      assert_equal assigns(:grade_entry_form).errors[:date][0], I18n.t('grade_entry_forms.invalid_date')
      assert_response :ok
    end

    # Test valid and invalid values for basic properties for :edit
    should 'POST on :edit with basic valid properties' do
      put_as @admin, :update, {id: @grade_entry_form.id,
                              grade_entry_form: {short_identifier: NEW_SHORT_IDENTIFIER,
                                                 description: NEW_DESCRIPTION,
                                                 message: NEW_MESSAGE,
                                                 date: @grade_entry_form.date}}
      assert_not_nil assigns :grade_entry_form
      assert_equal flash[:success], [I18n.t('grade_entry_forms.edit.success')]
      assert_response :redirect

      g = GradeEntryForm.find(@grade_entry_form.id)
      assert_equal NEW_SHORT_IDENTIFIER, g.short_identifier
      assert_equal NEW_DESCRIPTION, g.description
      assert_equal NEW_MESSAGE, g.message
    end

    should 'POST on :edit with missing required value' do
      post_as @admin, :update, {id: @grade_entry_form.id,
                              grade_entry_form: {short_identifier: '',
                                                 description: NEW_DESCRIPTION,
                                                 message: NEW_MESSAGE,
                                                 date: NEW_DATE}}
      assert_not_nil assigns :grade_entry_form
      assert_response :ok
      assert_nil flash[:error]
      assert_equal assigns(:grade_entry_form).errors[:short_identifier][0], I18n.t('grade_entry_forms.blank_field')

      g = GradeEntryForm.find(@grade_entry_form.id)
      assert_equal @original.short_identifier, g.short_identifier
      assert_equal @original.description, g.description
      assert_equal @original.message, g.message
      assert_equal @original.date, g.date
    end

    should 'POST on :edit with invalid basic value' do
      post_as @admin, :update, {id: @grade_entry_form.id,
                              grade_entry_form: {short_identifier: NEW_SHORT_IDENTIFIER,
                                                 description: NEW_DESCRIPTION,
                                                 message: NEW_MESSAGE,
                                                 date: 'abc'}}
      assert_not_nil assigns :grade_entry_form
      assert_response :ok
      assert_nil flash[:error]
      assert_equal assigns(:grade_entry_form).errors[:date][0], I18n.t('grade_entry_forms.invalid_date')

      g = GradeEntryForm.find(@grade_entry_form.id)
      assert_equal @original.short_identifier, g.short_identifier
      assert_equal @original.description, g.description
      assert_equal @original.message, g.message
      assert_equal @original.date, g.date
    end

    # Test valid and invalid values for GradeEntryItems for :new
    context 'POST on ' do
      setup do
        @original = @grade_entry_form
        @grade_entry_items = @grade_entry_form_with_grade_entry_items.grade_entry_items

        @q1 = { name: @grade_entry_items[0].name,
                out_of: @grade_entry_items[0].out_of,
                position: @grade_entry_items[0].position }
        @q2 = { name: @grade_entry_items[1].name,
                out_of: @grade_entry_items[1].out_of,
                position: @grade_entry_items[1].position }
        @q3 = { name: @grade_entry_items[2].name,
                out_of: @grade_entry_items[2].out_of,
                position: @grade_entry_items[2].position }
      end

      should ':new with valid properties, including 1 GradeEntryItem' do
        post_as @admin, :create, { grade_entry_form: {short_identifier: 'NT',
                                                      description: @grade_entry_form.description,
                                                      message: @grade_entry_form.message,
                                                      date: @grade_entry_form.date,
                                                      is_hidden: @grade_entry_form.is_hidden,
                                                      grade_entry_items_attributes: {'1' => @q1}} }
        assert_not_nil assigns :grade_entry_form
        assert_equal flash[:success], [I18n.t('grade_entry_forms.create.success')]
        assert_response :redirect
      end

      should ':new with valid properties, including multiple GradeEntryItems' do
        post_as @admin, :create, {grade_entry_form: {short_identifier: 'NT',
                                                     description: @grade_entry_form.description,
                                                     message: @grade_entry_form.message,
                                                     date: @grade_entry_form.date,
                                                     is_hidden: @grade_entry_form.is_hidden,
                                                     grade_entry_items_attributes: {'1' => @q1,
                                                                                    '2' => @q2,
                                                                                    '3' => @q3}}}
        assert_not_nil assigns :grade_entry_form
        assert_equal flash[:success], [I18n.t('grade_entry_forms.create.success')]
        assert_response :redirect
      end

      should ':new with valid properties, including multiple GradeEntryItems with missing positions' do
        @q1[:position] = nil
        @q2[:position] = nil
        @q3[:position] = nil
        items = [@q1, @q2, @q3]
        post_as @admin, :create, {grade_entry_form: {short_identifier: 'NT',
                                                     description: @grade_entry_form.description,
                                                     message: @grade_entry_form.message,
                                                     date: @grade_entry_form.date,
                                                     is_hidden: @grade_entry_form.is_hidden,
                                                     grade_entry_items_attributes: {'1' => @q1,
                                                                                    '2' => @q2,
                                                                                    '3' => @q3}}}
        assert_not_nil assigns :grade_entry_form
        assert_equal flash[:success], [I18n.t('grade_entry_forms.create.success')]
        assert_response :redirect

        g = GradeEntryForm.find_by_short_identifier('NT')

        (0...items.length).each do |i|
          assert_equal items[i][:name], g.grade_entry_items[i][:name]
          assert_equal items[i][:out_of], g.grade_entry_items[i][:out_of]
          assert_equal i+1, g.grade_entry_items[i][:position]
        end
      end

      should ':new with missing GradeEntryItem name' do
        @q2[:name] = ''
        post_as @admin,
                :create,
                {grade_entry_form: {
                    short_identifier: 'NT',
                    description: @grade_entry_form.description,
                    message: @grade_entry_form.message,
                    date: @grade_entry_form.date,
                    grade_entry_items_attributes: {'1' => @q1,
                                                      '2' => @q2}}}
        assert_not_nil assigns :grade_entry_form

        # Need to escape the I18n string because there is a '(e)' in French for
        # example
        assert_nil flash[:error]
        assert_equal [], @grade_entry_form.grade_entry_items
        assert_response :ok
      end

      should ':new with invalid GradeEntryItem out_of' do
        @q2[:out_of] = 'abc'
        post_as @admin,
                :create,
                {grade_entry_form: {
                    short_identifier: 'NT',
                    description: @grade_entry_form.description,
                    message: @grade_entry_form.message,
                    date: @grade_entry_form.date,
                    grade_entry_items_attributes: {'1' => @q1, '2' => @q2}}}
        assert_not_nil assigns :grade_entry_form
        assert_nil flash[:error]
        assert_equal [], @grade_entry_form.grade_entry_items
        assert_response :ok
      end

      should ':new with zero-value GradeEntryItem out_of' do
        @q2[:out_of] = 0
        post_as @admin,
                :create,
                {grade_entry_form: {
                    short_identifier: 'NT',
                    description: @grade_entry_form.description,
                    message: @grade_entry_form.message,
                    date: @grade_entry_form.date,
                    grade_entry_items_attributes: { '1' => @q1, '2' => @q2 },
                    is_hidden: false } }
        assert_not_nil assigns :grade_entry_form
        assert_equal flash[:success], [I18n.t('grade_entry_forms.create.success')]
        assert_response :redirect
      end

      should ':edit with valid properties, including one GradeEntryItem' do
        put_as @admin,
               :update,
               id: @grade_entry_form.id,
               grade_entry_form: {
                   short_identifier: NEW_SHORT_IDENTIFIER,
                   description: NEW_DESCRIPTION,
                   message: NEW_MESSAGE,
                   date: @grade_entry_form.date,
                   grade_entry_items_attributes: { '1' => @q1 },
                   is_hidden: false }
        assert_not_nil assigns :grade_entry_form
        assert_equal flash[:success], [I18n.t('grade_entry_forms.edit.success')]
        assert_response :redirect

        g = GradeEntryForm.find(@grade_entry_form.id)
        assert_equal NEW_SHORT_IDENTIFIER, g.short_identifier
        assert_equal NEW_DESCRIPTION, g.description
        assert_equal NEW_MESSAGE, g.message

        assert_equal 1, g.grade_entry_items.length
        assert_equal @q1[:name], g.grade_entry_items[0][:name]
        assert_equal @q1[:out_of], g.grade_entry_items[0][:out_of]
        assert_equal @q1[:position], g.grade_entry_items[0][:position]
      end

      should ':edit with valid properties, including multiple GradeEntryItems' do
        items = [@q1, @q2, @q3]
        put_as @admin,
               :update,
               id: @grade_entry_form.id,
               grade_entry_form: {
                   short_identifier: NEW_SHORT_IDENTIFIER,
                   description: NEW_DESCRIPTION,
                   message: NEW_MESSAGE,
                   date: @grade_entry_form.date,
                   grade_entry_items_attributes: {'1' => @q1,
                                                     '2' => @q2,
                                                     '3' => @q3 },
                   is_hidden: false }
        assert_not_nil assigns :grade_entry_form
        assert_equal flash[:success], [I18n.t('grade_entry_forms.edit.success')]
        assert_response :redirect

        g = GradeEntryForm.find(@grade_entry_form.id)
        assert_equal NEW_SHORT_IDENTIFIER, g.short_identifier
        assert_equal NEW_DESCRIPTION, g.description
        assert_equal NEW_MESSAGE, g.message
        assert_equal 3, g.grade_entry_items.length

        (0...items.length).each do |i|
          assert_equal items[i][:name], g.grade_entry_items[i][:name]
          assert_equal items[i][:out_of], g.grade_entry_items[i][:out_of]
          assert_equal items[i][:position], g.grade_entry_items[i][:position]
        end
      end

      should ':edit with valid properties, including multiple GradeEntryItems with missing positions' do
        @q2[:position] = nil
        @q3[:position] = nil

        put_as @admin,
               :update,
               id: @grade_entry_form.id,
               grade_entry_form: {
                                   short_identifier: NEW_SHORT_IDENTIFIER,
                                   description: NEW_DESCRIPTION,
                                   message: NEW_MESSAGE,
                                   date: @grade_entry_form.date,
                                   grade_entry_items_attributes: { '0' => @q2,
                                                                   '1' => @q1,
                                                                   '2' => @q3 },
                                   is_hidden: false }
        assert_not_nil assigns :grade_entry_form
        assert_equal flash[:success], [I18n.t('grade_entry_forms.edit.success')]
        assert_response :redirect

        g = GradeEntryForm.find(@grade_entry_form.id)
        assert_equal NEW_SHORT_IDENTIFIER, g.short_identifier
        assert_equal NEW_DESCRIPTION, g.description
        assert_equal NEW_MESSAGE, g.message
        assert_equal 3, g.grade_entry_items.length

        g.grade_entry_items.each do |item|
          if @q1[:name] == item[:name]
            assert_equal @q1[:out_of], item[:out_of]
          elsif @q2[:name] == item[:name]
            assert_equal @q2[:out_of], item[:out_of]
          else
            assert_equal @q3[:out_of], item[:out_of]
          end
        end
      end

      should ':edit with missing GradeEntryItem name' do
        @q1[:name] = ''
        post_as @admin, :update, {id: @grade_entry_form.id,
                                  grade_entry_form: {short_identifier: NEW_SHORT_IDENTIFIER,
                                                     description: NEW_DESCRIPTION,
                                                     message: NEW_MESSAGE,
                                                     date: @grade_entry_form.date,
                                                     is_hidden: false,
                                                     grade_entry_items_attributes: {'1' => @q1, '2' => @q2}}}
        assert_not_nil assigns :grade_entry_form
        assert_response :ok
        g = GradeEntryForm.find(@grade_entry_form.id)
        assert_equal @original.short_identifier, g.short_identifier
        assert_equal @original.description, g.description
        assert_equal @original.message, g.message
        assert_equal [], g.grade_entry_items
      end

      should ':edit with invalid GradeEntryItem out_of' do
        @q1[:out_of] = -10
        post_as @admin, :update, {id: @grade_entry_form.id,
                                  grade_entry_form: {short_identifier: NEW_SHORT_IDENTIFIER,
                                                     description: NEW_DESCRIPTION,
                                                     message: NEW_MESSAGE,
                                                     date: @grade_entry_form.date,
                                                     is_hidden: false,
                                                     grade_entry_items_attributes: {'1' => @q1, '2' => @q2}}}
        assert_not_nil assigns :grade_entry_form
        assert_response :ok
        assert_nil flash[:error]
        g = GradeEntryForm.find(@grade_entry_form.id)
        assert_equal @original.short_identifier, g.short_identifier
        assert_equal @original.description, g.description
        assert_equal @original.message, g.message
        assert_equal @original.grade_entry_items, g.grade_entry_items
      end

      should ':edit with zero-value GradeEntryItem out_of' do
        @q1[:out_of] = 0
        items = [@q1, @q2]
        put_as @admin,
               :update,
               id: @grade_entry_form.id,
               grade_entry_form: {
                   short_identifier: NEW_SHORT_IDENTIFIER,
                   description: NEW_DESCRIPTION,
                   message: NEW_MESSAGE,
                   date: @grade_entry_form.date,
                   is_hidden: false,
                   grade_entry_items_attributes: {'1' => @q1, '2' => @q2}}
        assert_not_nil assigns :grade_entry_form
        assert_equal flash[:success], [I18n.t('grade_entry_forms.edit.success')]
        assert_response :redirect

        g = GradeEntryForm.find(@grade_entry_form.id)
        assert_equal NEW_SHORT_IDENTIFIER, g.short_identifier
        assert_equal NEW_DESCRIPTION, g.description
        assert_equal NEW_MESSAGE, g.message
        assert_equal 2, g.grade_entry_items.length

        (0...items.length).each do |i|
          assert_equal items[i][:name], g.grade_entry_items[i][:name]
          assert_equal items[i][:out_of], g.grade_entry_items[i][:out_of]
          assert_equal items[i][:position], g.grade_entry_items[i][:position]
        end
      end

      should ':edit with duplicate GradeEntryItem name' do
        @grade_entry_form_with_dup = GradeEntryForm.make
        @q1[:name] = 'Q1'
        @q2[:name] = 'Q1'
        @grade_entry_form_with_dup.grade_entry_items.make(name: @q1[:name], position: 1)
        @grade_entry_form_before = @grade_entry_form_with_dup

        post_as @admin, :update, {id: @grade_entry_form_with_dup.id,
                                  grade_entry_form: {short_identifier: NEW_SHORT_IDENTIFIER,
                                                     description: NEW_DESCRIPTION,
                                                     message: NEW_MESSAGE,
                                                     date: @grade_entry_form_with_dup.date,
                                                     is_hidden: false,
                                                     grade_entry_items_attributes: {'1' => @q1,
                                                                                    '2' => @q2}}}
        @grade_entry_form_before.reload
        assert_not_nil assigns :grade_entry_form
        assert_response :ok
        assert_nil flash[:error]
        assert_equal 1, @grade_entry_form_with_dup.grade_entry_items.length
        g = GradeEntryForm.find(@grade_entry_form_with_dup.id)
        assert_equal @grade_entry_form_before.short_identifier, g.short_identifier
        assert_equal @grade_entry_form_before.description, g.description
        assert_equal @grade_entry_form_before.message, g.message
        assert_equal @grade_entry_form_before.grade_entry_items, g.grade_entry_items
      end
    end

    # Test updating grades
    context 'POST on :update_grade when the Grade has an existing value - ' do
      setup do
        @grade_entry_items = @grade_entry_form_with_grade_entry_items.grade_entry_items
        student = Student.make
        @grade_entry_student_with_some_grades = @grade_entry_form_with_grade_entry_items.grade_entry_students.find_by(user: student)
        @grade_entry_student_with_some_grades.grades.make(grade_entry_item: @grade_entry_items[0],
                                                          grade: 3)
        @grade_entry_student_with_some_grades.grades.make(grade_entry_item: @grade_entry_items[1],
                                                          grade: 7)
      end

      should 'change the existing value to a valid value' do
        @new_grade = 4
        post_as @admin,
                :update_grade,
                format: :js,
                grade_entry_item_id: @grade_entry_items[0].id,
                student_id: @grade_entry_student_with_some_grades.user_id,
                updated_grade: @new_grade,
                id: @grade_entry_form_with_grade_entry_items.id
        assert_not_nil assigns :grade
        assert render_template :update_grade
        assert_response :success
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student_with_some_grades.id,
                                                                              @grade_entry_items[0].id)
        assert_equal @new_grade, grade.grade
      end

      should 'attempt to change the existing value to a string' do
        @new_grade = 'abc'
        @original_grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student_with_some_grades.id,
                                                                                        @grade_entry_items[0].id).grade
        post_as @admin,
                :update_grade,
                format: :js,
                grade_entry_item_id: @grade_entry_items[0].id,
                student_id: @grade_entry_student_with_some_grades.user_id,
                updated_grade: @new_grade,
                id: @grade_entry_form_with_grade_entry_items.id
        assert_not_nil assigns :grade
        assert render_template :update_grade
        assert_response :success
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student_with_some_grades.id,
                                                                              @grade_entry_items[0].id)
        assert_equal @original_grade, grade.grade
      end

      should 'attempt to change the value of an existing grade to a negative number' do
        @new_grade = -5
        @original_grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student_with_some_grades.id,
                                                                                        @grade_entry_items[0].id).grade
        post_as @admin,
                :update_grade,
                format: :js,
                grade_entry_item_id: @grade_entry_items[0].id,
                student_id: @grade_entry_student_with_some_grades.user_id,
                updated_grade: @new_grade,
                id: @grade_entry_form_with_grade_entry_items.id
        assert_not_nil assigns :grade
        assert render_template :update_grade
        assert_response :success
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student_with_some_grades.id,
                                                                              @grade_entry_items[0].id)
        assert_equal @original_grade, grade.grade
      end
    end

    context 'POST on :update_grade when the Grade does not have an existing value and the GradeEntryStudent does exist - ' do
      setup do
        @grade_entry_items = @grade_entry_form_with_grade_entry_items.grade_entry_items
        student = Student.make
        @grade_entry_student = @grade_entry_form_with_grade_entry_items.grade_entry_students.find_by(user: student)
      end

      should 'set an empty grade to a valid value' do
        @new_grade = 2.5
        post_as @admin,
                :update_grade,
                format: :js,
                grade_entry_item_id: @grade_entry_items[0].id,
                student_id: @grade_entry_student.user_id,
                updated_grade: @new_grade,
                id: @grade_entry_form_with_grade_entry_items.id
        assert_not_nil assigns :grade
        assert render_template :update_grade
        assert_response :success
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student.id,
                                                                              @grade_entry_items[0].id)
        assert_equal @new_grade, grade.grade
      end

      should 'attempt to set an empty grade to a string' do
        @new_grade = 'abc'
        post_as @admin,
                :update_grade,
                format: :js,
                grade_entry_item_id: @grade_entry_items[0].id,
                student_id: @grade_entry_student.user_id,
                updated_grade: @new_grade,
                id: @grade_entry_form_with_grade_entry_items.id
        assert_not_nil assigns :grade
        assert render_template :update_grade
        assert_response :success
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student.id,
                                                                              @grade_entry_items[0].id)
        assert_nil grade.grade
      end

      should 'attempt to set an empty grade to a negative number' do
        @new_grade = -7
        post_as @admin,
                :update_grade,
                format: :js,
                grade_entry_item_id: @grade_entry_items[0].id,
                student_id: @grade_entry_student.user_id,
                updated_grade: @new_grade,
                id: @grade_entry_form_with_grade_entry_items.id
        assert_not_nil assigns :grade
        assert render_template :update_grade
        assert_response :success
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student.id,
                                                                              @grade_entry_items[0].id)
        assert_nil grade.grade
      end
    end

    context 'POST on :update_grade when the Grade does not have an existing value and the GradeEntryStudent does not exist - ' do
      setup do
        @grade_entry_items = @grade_entry_form_with_grade_entry_items.grade_entry_items
        @student = Student.make
      end

      should 'set an empty grade to a valid value' do
        @new_grade = 2.5
        post_as @admin,
                :update_grade,
                format: :js,
                grade_entry_item_id: @grade_entry_items[0].id,
                student_id: @student.id,
                updated_grade: @new_grade,
                id: @grade_entry_form_with_grade_entry_items.id
        assert_not_nil assigns :grade
        assert render_template :update_grade
        assert_response :success
        grade_entry_student = @grade_entry_form_with_grade_entry_items.grade_entry_students.find_by(user: @student)
        assert_not_nil grade_entry_student
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(grade_entry_student.id,
                                                                              @grade_entry_items[0].id)
        assert_equal @new_grade, grade.grade
      end

      should 'attempt to set an empty grade to a string' do
        @new_grade = 'abc'
        post_as @admin,
                :update_grade,
                format: :js,
                grade_entry_item_id: @grade_entry_items[0].id,
                student_id: @student.id,
                updated_grade: @new_grade,
                id: @grade_entry_form_with_grade_entry_items.id
        assert_not_nil assigns :grade
        assert render_template :update_grade
        assert_response :success
        grade_entry_student = @grade_entry_form_with_grade_entry_items.grade_entry_students.find_by(user: @student)
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(grade_entry_student.id, @grade_entry_items[0].id)
        assert_nil grade.grade
      end

      should 'attempt to set an empty grade to a negative number' do
        @new_grade = -7
        post_as @admin,
                :update_grade,
                format: :js,
                grade_entry_item_id: @grade_entry_items[0].id,
                student_id: @student.id,
                updated_grade: @new_grade,
                id: @grade_entry_form_with_grade_entry_items.id
        assert_not_nil assigns :grade
        assert render_template :update_grade
        assert_response :success
        grade_entry_student = @grade_entry_form_with_grade_entry_items.grade_entry_students.find_by(user: @student)
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(grade_entry_student.id, @grade_entry_items[0].id)
        assert_nil grade.grade
      end
    end

    # Test releasing/unreleasing the marks
    context 'POST on :update_grade_entry_students: ' do
      setup do
        last_names = %w(Albert Alwyn Auric Berio Bliss Bridge Britten Cage
                        Dukas Duparc Egge Feldman)
        @grade_entry_form1 = make_grade_entry_form_with_multiple_grade_entry_items
        @students = []
        @specific_students = []
        (0..11).each do |i|
          student = Student.make(user_name: 's' + i.to_s, last_name: last_names[i], first_name: 'Bob')
          @students << student
        end
      end

      should 'release the marks for particular students' do
        @specific_students = [@students[0].id, @students[1].id, @students[2].id]
        post_as @admin, :update_grade_entry_students, {students: @specific_students,
                                                       filter: 'none',
                                                       ap_select_full: false,
                                                       release_results: true,
                                                       id: @grade_entry_form1.id}
        assert_response :success
        (0..2).each do |i|
          grade_entry_student = @grade_entry_form1.grade_entry_students.find_by(user: @students[i])
          assert_equal true, grade_entry_student.released_to_student
        end

        (3..(@students.size-1)).each do |i|
          grade_entry_student = @grade_entry_form1.grade_entry_students.find_by(user: @students[i])
          assert_equal false, grade_entry_student.released_to_student
        end
      end

      should 'release the marks for all of the students' do
        (0..(@students.size-1)).each do |i|
          @specific_students << @students[i].id
        end
        post_as @admin, :update_grade_entry_students, {students: @specific_students,
                                                       filter: 'none',
                                                       ap_select_full: true,
                                                       release_results: true,
                                                       id: @grade_entry_form1.id}
        assert_response :success
        (0..(@specific_students.size-1)).each do |i|
          grade_entry_student = @grade_entry_form1.grade_entry_students.find_by(user: @students[i])
          assert_equal true, grade_entry_student.released_to_student
        end
      end

      should 'unrelease the marks for particular students' do
        @specific_students = [@students[0].id, @students[1].id, @students[2].id]
        post_as @admin, :update_grade_entry_students, {students: @specific_students,
                                                       filter: 'none',
                                                       ap_select_full: false,
                                                       unrelease_results: false,
                                                       id: @grade_entry_form1.id}
        assert_response :success
        (0..2).each do |i|
          grade_entry_student = @grade_entry_form1.grade_entry_students.find_by(user: @students[i])
          assert_equal false, grade_entry_student.released_to_student
        end
      end

      should 'unrelease the marks for all of the students' do
        (0..(@students.size-1)).each do |i|
          @specific_students << @students[i].id
        end
        post_as @admin, :update_grade_entry_students, {students: @specific_students,
                                                       filter: 'none',
                                                       ap_select_full: true,
                                                       unrelease_results: true,
                                                       id: @grade_entry_form1.id}
        assert_response :success
        (0..(@specific_students.size-1)).each do |i|
          grade_entry_student = @grade_entry_form1.grade_entry_students.find_by(user: @students[i])
          assert_equal false, grade_entry_student.released_to_student
        end
      end
    end

    context 'POST on :csv_upload without a .csv file' do
      setup do
        @student = Student.make(user_name: 'c2ÈrÉØrr', last_name: 'Last', first_name: 'First')
        @grade_entry_form = GradeEntryForm.make
        @grade_entry_student = @grade_entry_form.grade_entry_students.find_by(user: @student)
        @grade_entry_item = @grade_entry_form.grade_entry_items.make(name: 'something', position: 1)
        @current_grade = 5.0
        @grade_entry_student.grades.make(grade_entry_item: @grade_entry_item, grade: @current_grade)
      end

      should 'display an error when uploading nothing and leave the db unchanged' do
        post_as @admin,
                :csv_upload,
                id: @grade_entry_form.id,
                upload: nil,
                encoding: 'UTF-8'
        assert_response :redirect
        assert_equal flash[:error], [I18n.t('csv.invalid_csv')]
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
            @grade_entry_student.id, @grade_entry_item.id
        )
        assert_not_nil grade
        assert_equal @current_grade, grade.grade
      end

      should 'display an error when uploading a non-csv file and leave the db unchanged' do
        post_as @admin,
                :csv_upload,
                id: @grade_entry_form.id,
                upload: {grades_file: fixture_file_upload('files/failfile.txt')},
                encoding: 'UTF-8'
        assert_response :redirect
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
            @grade_entry_student.id, @grade_entry_item.id
        )
        assert_not_nil grade
        assert_equal @current_grade, grade.grade
      end

      should 'display an error when uploading a malformed csv file and leave the db unchanged' do
        tempfile = fixture_file_upload('files/malformed.csv')
        post_as @admin,
                :csv_upload,
                id: @grade_entry_form.id,
                upload: { grades_file: tempfile },
                encoding: 'UTF-8'

        assert_response :redirect
        assert_equal flash[:error], [I18n.t('csv.upload.malformed_csv')]
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
          @grade_entry_student.id, @grade_entry_item.id
        )
        assert_not_nil grade
        assert_equal @current_grade, grade.grade
      end

      should 'display an error when uploading a non csv file with a csv extension and leave the db unchanged' do
        tempfile = fixture_file_upload('files/pdf_with_csv_extension.csv')
        post_as @admin,
                :csv_upload,
                id: @grade_entry_form.id,
                upload: { grades_file: tempfile },
                encoding: 'UTF-8'

        assert_response :redirect
        assert_equal flash[:error],
                     [I18n.t('csv.upload.non_text_file_with_csv_extension')]
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
          @grade_entry_student.id, @grade_entry_item.id
        )
        assert_not_nil grade
        assert_equal @current_grade, grade.grade
      end
    end

    # TODO: These tests failed on Travis, but passed locally.
=begin
    context 'POST on :csv_upload with column already in db ' do
      setup do
        @student = Student.make(user_name: 'c2ÈrÉØrr', last_name: 'Last', first_name: 'First')
        @grade_entry_form = GradeEntryForm.make
        @grade_entry_student = @grade_entry_form.grade_entry_students.make(user: @student)
        @grade_entry_item = @grade_entry_form.grade_entry_items.make(name: 'something', position: 1)
        @old_grade = 0.0
        @new_grade = 10.0
        @grade_entry_student.grades.make(grade_entry_item: @grade_entry_item, grade: @old_grade)
      end

      should 'have valid values in database after an upload of a UTF-8 encoded file parsed as UTF-8' do
        post_as @admin,
                :csv_upload,
                id: @grade_entry_form.id,
                upload: {grades_file: fixture_file_upload('files/test_grades_UTF-8.csv')},
                encoding: 'UTF-8',
                overwrite: true
        assert_response :redirect
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
            @grade_entry_student.id, @grade_entry_item.id
        )
        assert_not_nil grade
        assert_equal @new_grade, grade.grade
      end

      should 'have valid values in database after an upload of a ISO-8859-1 encoded file parsed as ISO-8859-1' do
        post_as @admin,
                :csv_upload,
                id: @grade_entry_form.id,
                upload: {grades_file: fixture_file_upload('files/test_grades_ISO-8859-1.csv')},
                encoding: 'ISO-8859-1',
                overwrite: true
        assert_response :redirect
        grade_entry_item = GradeEntryItem.find_by_id(@grade_entry_item.id)
        assert_not_nil grade_entry_item
        assert_equal 'something', grade_entry_item.name
        assert_equal 10, grade_entry_item.out_of
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
            @grade_entry_student.id, @grade_entry_item.id
        )
        assert_not_nil grade
        assert_equal @new_grade, grade.grade

      end

      should 'have invalid values in database after an upload of a UTF-8 encoded file parsed as ISO-8859-1' do
        post_as @admin,
                :csv_upload,
                id: @grade_entry_form_with_grade_entry_items.id,
                upload: {grades_file: fixture_file_upload('files/test_grades_UTF-8.csv')},
                encoding: 'ISO-8859-1',
                overwrite: true
        assert_response :redirect
        test_student = Student.find_by_user_name('c2ÈrÉØrr')
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
            @grade_entry_student.id, @grade_entry_item.id
        )
        assert_not_nil grade
        assert_equal @old_grade, grade.grade
      end

      should 'update column out_of' do
        same_name = 'something'
        new_out_of = 10
        post_as @admin,
                :csv_upload,
                id: @grade_entry_form.id,
                upload: {grades_file: fixture_file_upload('files/test_grades_UTF-8.csv')},
                encoding: 'UTF-8'
        assert_response :redirect
        grade_entry_item = GradeEntryItem.find_by_id(@grade_entry_item.id)
        assert_not_nil grade_entry_item
        assert_equal same_name, grade_entry_item.name
        assert_equal new_out_of, grade_entry_item.out_of
      end

      should 'update old grades' do
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
            @grade_entry_student.id, @grade_entry_item.id
        )
        assert_not_nil grade
        assert_equal @old_grade, grade.grade
        post_as @admin,
                :csv_upload,
                id: @grade_entry_form.id,
                upload: {grades_file: fixture_file_upload('files/test_grades_UTF-8.csv')},
                encoding: 'UTF-8',
                overwrite: true
        assert_response :redirect
        grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
            @grade_entry_student.id, @grade_entry_item.id
        )
        assert_not_nil grade
        assert_equal @new_grade, grade.grade
      end
    end

    context 'POST on :csv_upload with column not in db ' do
      setup do
        @student = Student.make(user_name: 'c2ÈrÉØrr', last_name: 'Last', first_name: 'First')
        @grade_entry_form = GradeEntryForm.make
        @grade_entry_student = @grade_entry_form.grade_entry_students.make(user: @student)
        @grade_entry_item = @grade_entry_form.grade_entry_items.make(name: 'not_something', position: 1)
        @grade_entry_student.grades.make(grade_entry_item: @grade_entry_item, grade: @old_grade)
      end

      context 'when overwriting existing grades ' do
        should 'delete unused columns' do
          post_as @admin,
                  :csv_upload,
                  id: @grade_entry_form.id,
                  upload: {grades_file: fixture_file_upload('files/test_grades_UTF-8.csv')},
                  encoding: 'UTF-8',
                  overwrite: true
          assert_response :redirect

          grade_entry_item = GradeEntryItem.find_by_id(@grade_entry_item.id)
          assert_nil grade_entry_item
        end

        should 'delete unused grades' do
          post_as @admin,
                  :csv_upload,
                  id: @grade_entry_form.id,
                  upload: {grades_file: fixture_file_upload('files/test_grades_UTF-8.csv')},
                  encoding: 'UTF-8',
                  overwrite: true
          assert_response :redirect
          old_grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
              @grade_entry_student.id, @grade_entry_item.id
          )
          assert_nil old_grade
          new_grade_entry_item = GradeEntryItem.find_by_name('something')
          assert_not_nil new_grade_entry_item
          new_grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
              @grade_entry_student.id, new_grade_entry_item.id
          )
          assert_not_nil new_grade
        end
      end

      context 'when not overwriting existing grades ' do
        should 'not delete unused columns' do
          post_as @admin,
                  :csv_upload,
                  id: @grade_entry_form.id,
                  upload: {grades_file: fixture_file_upload('files/test_grades_UTF-8.csv')},
                  encoding: 'UTF-8',
                  overwrite: false
          assert_response :redirect

          grade_entry_item = GradeEntryItem.find_by_id(@grade_entry_item.id)
          assert_not_nil grade_entry_item
        end

        should 'not delete unused grades' do
          post_as @admin,
                  :csv_upload,
                  id: @grade_entry_form.id,
                  upload: {grades_file: fixture_file_upload('files/test_grades_UTF-8.csv')},
                  encoding: 'UTF-8',
                  overwrite: false
          assert_response :redirect
          old_grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
            @grade_entry_student.id, @grade_entry_item.id
          )
          assert_not_nil old_grade
          new_grade_entry_item = GradeEntryItem.find_by_name('something')
          assert_not_nil new_grade_entry_item
          new_grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(
            @grade_entry_student.id, new_grade_entry_item.id
          )
          assert_not_nil new_grade
        end
      end

      should 'add new columns' do
        post_as @admin,
                :csv_upload,
                id: @grade_entry_form.id,
                upload: {grades_file: fixture_file_upload('files/test_grades_UTF-8.csv')},
                encoding: 'UTF-8'
        assert_response :redirect

        grade_entry_item = GradeEntryItem.find_by_name('something')
        assert_not_nil grade_entry_item
      end
    end
=end
  end
end
