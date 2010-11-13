require File.dirname(__FILE__) + '/authenticated_controller_test'
require File.join(File.dirname(__FILE__),'/../blueprints/blueprints')
require File.join(File.dirname(__FILE__), '/../blueprints/helper')
require 'shoulda'
require 'will_paginate'

class GradeEntryFormsControllerTest < AuthenticatedControllerTest

  def setup
    clear_fixtures
  end
  
  # Constants for :edit tests
  NEW_SHORT_IDENTIFIER = "NewSI"
  NEW_DESCRIPTION = "NewDescription"
  NEW_MESSAGE = "NewMessage"
  NEW_DATE = 3.days.from_now
  
  # An authenticated and authorized student
  context "An authenticated and authorized student doing a " do
    setup do
      @student = Student.make
      @grade_entry_form = GradeEntryForm.make
      @grade_entry_form_with_grade_entry_items = make_grade_entry_form_with_multiple_grade_entry_items
      @grade_entry_student = @grade_entry_form_with_grade_entry_items.grade_entry_students.make(:user => @student)
      @grade_entry_form_with_grade_entry_items.grade_entry_items.each do |grade_entry_item|
        @grade_entry_student.grades.make(:grade_entry_item => grade_entry_item, :grade => 5)
      end
    end
    
    # Students are not allowed to create or edit grade entry form properties
    context "GET on :new" do
      setup do
        get_as @student, :new
      end
      should respond_with :missing
    end
    
    context "GET on :edit" do
      setup do
        get_as @student, :edit, :id => 1
      end
      should respond_with :missing
    end
    
    context "GET on :grades" do
      setup do
        get_as @student, :grades, :id => 1
      end
      should respond_with :missing
    end
    
    # Test that the students can access the student_interface
    context "GET on :student_interface when no marks have been entered for this student" do
      setup do
        get_as @student, :student_interface, :id => @grade_entry_form.id
      end
      should assign_to :grade_entry_form
      should assign_to :student
      should render_template :student_interface
      should respond_with :success
      should_not set_the_flash
      should "verify that the 'grade_entry_forms.students.no_results' message made it to the response" do
        assert_match Regexp.new(I18n.t('grade_entry_forms.students.no_results')), @response.body
      end
    end
    
    context "GET on :student_interface when marks have been entered for this student and have been released" do
      setup do
        @grade_entry_student.released_to_student = true
        @grade_entry_student.save
        get_as @student, :student_interface, :id => @grade_entry_form_with_grade_entry_items.id
      end
      should assign_to :grade_entry_form
      should assign_to :student
      should render_template :student_interface
      should respond_with :success
      should_not set_the_flash
      should "verify that the 'grade_entry_forms.grades.total' message and the total mark made it to the response" do
        assert_match Regexp.new(I18n.t('grade_entry_forms.grades.total')), @response.body
        assert_match Regexp.new("15"), @response.body
      end
    end
    
    context "GET on :student_interface when marks have been entered for this student but have not been released" do
      setup do 
        get_as @student, :student_interface, :id => @grade_entry_form_with_grade_entry_items.id
      end
      should assign_to :grade_entry_form
      should assign_to :student
      should render_template :student_interface
      should respond_with :success
      should_not set_the_flash
      should "verify that the 'grade_entry_forms.students.no_results' message made it to the response" do
        assert_match Regexp.new(I18n.t('grade_entry_forms.students.no_results')), @response.body
      end
    end
    
    context "GET on :student_interface when the student's mark has been released and it is a blank mark" do
      setup do 
        student1 = Student.make
        grade_entry_student1 = @grade_entry_form_with_grade_entry_items.grade_entry_students.make(:user => student1)
        grade_entry_student1.released_to_student=true
        grade_entry_student1.save
        grade_entry_student1 = @grade_entry_form.grade_entry_students.find_by_user_id(student1.id)
        get_as student1, :student_interface, :id => @grade_entry_form_with_grade_entry_items.id
      end
      should assign_to :grade_entry_form
      should assign_to :student
      should render_template :student_interface
      should respond_with :success
      should_not set_the_flash
      should "verify that the 'grade_entry_forms.grades.no_mark' message made it to the response" do
        assert_match Regexp.new(I18n.t('grade_entry_forms.grades.no_mark')), @response.body
      end
    end
    
    context "POST on :new" do
      setup do
        post_as @student, :new
      end
      should respond_with :missing
    end
    
    context "POST on :edit" do
      setup do
        post_as @student, :edit, :id => 1
      end
      should respond_with :missing
    end
    
    context "POST on :grades" do
      setup do
        post_as @student, :grades, :id => 1
      end
      should respond_with :missing
    end
    
    context "POST on :student_interface" do
      setup do
        post_as @student, :student_interface, :id => @grade_entry_form.id
      end
      should assign_to :grade_entry_form
      should assign_to :student
      should render_template :student_interface
      should respond_with :success
      should_not set_the_flash
    end
  end
  
  # An authenitcated and authorized TA
  context "An authenticated and authorized TA doing a " do
    setup do
      @ta = Ta.make
    end
    
    # TAs are not allowed to create or edit grade entry form properties or access
    # the student interface
    context "GET on :new" do
      setup do
        get_as @ta, :new
      end
      should respond_with :missing
    end
    
    context "GET on :edit" do
      setup do
        get_as @ta, :edit, :id => 1
      end
      should respond_with :missing
    end
    
    context "GET on :student_interface" do
      setup do
        get_as @ta, :student_interface, :id => 1
      end
      should respond_with :missing
    end
    
    context "POST on :new" do
      setup do
        post_as @ta, :new 
      end
      should respond_with :missing
    end
    
    context "POST on :edit" do
      setup do
        post_as @ta, :edit
      end
      should respond_with :missing
    end
    
    context "POST on :student_interface" do
      setup do
        post_as @ta, :student_interface
      end
      should respond_with :missing
    end
  end
  
  # An authenticated and authorized admin
  context "An authenticated and authorized admin doing a " do
    setup do
      @admin = Admin.make
      @grade_entry_form = GradeEntryForm.make
      @grade_entry_form_with_grade_entry_items = make_grade_entry_form_with_multiple_grade_entry_items
      @original = @grade_entry_form
      @original_with_grade_entry_items = @grade_entry_form_with_grade_entry_items
      10.times {Student.make}
    end
    
    context "GET on :new" do
      setup do
        get_as @admin, :new
      end
      should assign_to :grade_entry_form
      should render_template :new
      should respond_with :success
      should_not set_the_flash
    end
    
    context "GET on :edit" do 
      setup do
        get_as @admin, :edit, :id => @grade_entry_form.id
      end
      should assign_to :grade_entry_form
      should render_template :edit
      should respond_with :success
      should_not set_the_flash
    end
    
    context "GET on :student_interface" do
      setup do
        get_as @admin, :student_interface
      end
      should respond_with :missing
    end
    
    context "GET on :grades when there are no grade entry items" do 
      setup do
        get_as @admin, :grades, :id => @grade_entry_form.id
      end
      should assign_to :grade_entry_form
      should render_template :grades
      should respond_with :success
      should "verify that the no_grade_entry_items message made it to the response" do
        assert_match Regexp.new(I18n.t('grade_entry_forms.grades.no_grade_entry_items_message')), @response.body
      end
    end
    
    context "GET on :grades when there are grade entry items" do 
      setup do
        get_as @admin, :grades, :id => @grade_entry_form_with_grade_entry_items.id
      end
      should assign_to :grade_entry_form
      should render_template :grades
      should respond_with :success 
    end
    
    context "POST on :student_interface" do
      setup do
        post_as @admin, :student_interface
      end
      should respond_with :missing
    end
    
    # Test valid and invalid values for basic properties for :new
    context "POST on :new with basic valid properties" do 
      setup do
        post_as @admin, :new, {:grade_entry_form => {:short_identifier => "NT", 
                                                     :description => @grade_entry_form.description,
                                                     :message => @grade_entry_form.message,
                                                     :date => @grade_entry_form.date}}
      end
      should assign_to :grade_entry_form
      should set_the_flash.to(I18n.t('grade_entry_forms.create.success'))
      should respond_with :redirect
    end
    
    context "POST on :new with a missing required value" do 
      setup do
        post_as @admin, :new, {:grade_entry_form => {:short_identifier => "", 
                                                     :description => @grade_entry_form.description,
                                                     :message => @grade_entry_form.message,
                                                     :date => @grade_entry_form.date}}
      end
      should assign_to :grade_entry_form
      should "verify that the error message made it to the response" do
        assert_match Regexp.new(Regexp.escape(I18n.t('grade_entry_forms.blank_field'))), @response.body
      end
      should respond_with :success
    end
   
    context "POST on :new with an invalid basic value" do 
      setup do
        post_as @admin, :new, {:id => @grade_entry_form.id, 
                               :grade_entry_form => {:short_identifier => "NT", 
                                                     :description => @grade_entry_form.description,
                                                     :message => @grade_entry_form.message,
                                                     :date => "abcd"}}
      end
      should assign_to :grade_entry_form
      should "verify that the error message made it to the response" do
        assert_match Regexp.new(I18n.t('grade_entry_forms.invalid_date')), @response.body
      end
      should respond_with :success
    end
    
    # Test valid and invalid values for basic properties for :edit
    context "POST on :edit with basic valid properties" do 
      setup do
        post_as @admin, :edit, {:id => @grade_entry_form.id,
                                :grade_entry_form => {:short_identifier => NEW_SHORT_IDENTIFIER, 
                                                     :description => NEW_DESCRIPTION,
                                                     :message => NEW_MESSAGE,
                                                     :date => @grade_entry_form.date}}
      end
      should assign_to :grade_entry_form
      should set_the_flash.to(I18n.t('grade_entry_forms.edit.success'))
      should respond_with :redirect
      
      should "verify that the property values were actually updated" do
        g = GradeEntryForm.find(@grade_entry_form.id)
        assert_equal NEW_SHORT_IDENTIFIER, g.short_identifier
        assert_equal NEW_DESCRIPTION, g.description
        assert_equal NEW_MESSAGE, g.message
      end
    end
    
    context "POST on :edit with missing required value" do 
      setup do
        post_as @admin, :edit, {:id => @grade_entry_form.id,
                                :grade_entry_form => {:short_identifier => "", 
                                                     :description => NEW_DESCRIPTION,
                                                     :message => NEW_MESSAGE,
                                                     :date => NEW_DATE}}
      end
      should assign_to :grade_entry_form
      should respond_with :success
      
      should "verify that the error message made it to the response" do
        assert_match Regexp.new(Regexp.escape(I18n.t('grade_entry_forms.blank_field'))), @response.body
      end
      
      should "verify that the property values were not updated" do
        g = GradeEntryForm.find(@grade_entry_form.id)
        assert_equal @original.short_identifier, g.short_identifier
        assert_equal @original.description, g.description
        assert_equal @original.message, g.message
        assert_equal @original.date, g.date
      end
    end
    
    context "POST on :edit with invalid basic value" do 
      setup do
        post_as @admin, :edit, {:id => @grade_entry_form.id,
                                :grade_entry_form => {:short_identifier => NEW_SHORT_IDENTIFIER, 
                                                     :description => NEW_DESCRIPTION,
                                                     :message => NEW_MESSAGE,
                                                     :date => "abc"}}
      end
      should assign_to :grade_entry_form
      should respond_with :success
      
      should "verify that the error message made it to the response" do
        assert_match Regexp.new(I18n.t('grade_entry_forms.invalid_date')), @response.body
      end
      
      should "verify that the property values were not updated" do
        g = GradeEntryForm.find(@grade_entry_form.id)
        assert_equal @original.short_identifier, g.short_identifier
        assert_equal @original.description, g.description
        assert_equal @original.message, g.message
        assert_equal @original.date, g.date
      end
    end
     
    # Test valid and invalid values for GradeEntryItems for :new
    context "POST on " do
      setup do
        @original = @grade_entry_form
        grade_entry_items = @grade_entry_form_with_grade_entry_items.grade_entry_items
        @q1 = GradeEntryItem.new(:name => grade_entry_items[0].name, :out_of => grade_entry_items[0].out_of)
        @q2 = GradeEntryItem.new(:name => grade_entry_items[1].name, :out_of => grade_entry_items[1].out_of)
        @q3 = GradeEntryItem.new(:name => grade_entry_items[2].name, :out_of => grade_entry_items[2].out_of)
      end
      
      context ":new with valid properties, including 1 GradeEntryItem" do 
        setup do
          post_as @admin, :new, { :grade_entry_form => {:short_identifier => "NT", 
                                                        :description => @grade_entry_form.description,
                                                        :message => @grade_entry_form.message,
                                                        :date => @grade_entry_form.date,
                                                        :grade_entry_items => [@q1]}}
        end
        should assign_to :grade_entry_form
        should set_the_flash.to(I18n.t('grade_entry_forms.create.success'))
        should respond_with :redirect
      end
    
      context ":new with valid properties, including multiple GradeEntryItems" do 
        setup do
          post_as @admin, :new, {:grade_entry_form => {:short_identifier => "NT", 
                                                       :description => @grade_entry_form.description,
                                                       :message => @grade_entry_form.message,
                                                       :date => @grade_entry_form.date,
                                                       :grade_entry_items => [@q1, @q2, @q3]}}
        end
        should assign_to :grade_entry_form
        should set_the_flash.to(I18n.t('grade_entry_forms.create.success'))
        should respond_with :redirect
      end
      
      context ":new with missing GradeEntryItem name" do 
        setup do
          @q2.name = ""
          post_as @admin, :new, {:grade_entry_form => {:short_identifier => "NT", 
                                                       :description => @grade_entry_form.description,
                                                       :message => @grade_entry_form.message,
                                                       :date => @grade_entry_form.date,
                                                       :grade_entry_items => [@q1, @q2]}}
        end
        should assign_to :grade_entry_form
        should "verify that the error message made it to the response" do
          #Need to escape the I18n string because there is a '(e)' in French for example
          assert_match Regexp.new(Regexp.escape(I18n.t('grade_entry_forms.blank_field'))), @response.body
        end
        should respond_with :success
      end
      
      context ":new with invalid GradeEntryItem out_of" do 
        setup do
          @q2.out_of = "abc"
          post_as @admin, :new, {:grade_entry_form => {:short_identifier => "NT", 
                                                       :description => @grade_entry_form.description,
                                                       :message => @grade_entry_form.message,
                                                       :date => @grade_entry_form.date,
                                                       :grade_entry_items => [@q1, @q2]}}
        end
        should assign_to :grade_entry_form
        should "verify that the error message made it to the response" do
          assert_match Regexp.new(I18n.t('grade_entry_forms.invalid_column_out_of')), @response.body
        end
        should respond_with :success
      end
      
      context ":new with zero-value GradeEntryItem out_of" do 
        setup do
          @q2.out_of = 0
          post_as @admin, :new, {:grade_entry_form => {:short_identifier => "NT", 
                                                       :description => @grade_entry_form.description,
                                                       :message => @grade_entry_form.message,
                                                       :date => @grade_entry_form.date,
                                                       :grade_entry_items => [@q1, @q2]}}
        end
        should assign_to :grade_entry_form
        should set_the_flash.to(I18n.t('grade_entry_forms.create.success'))
        should respond_with :redirect
      end
      
      context ":edit with valid properties, including an additional GradeEntryItem" do 
        setup do
          post_as @admin, :edit, {:id => @grade_entry_form.id, 
                                  :grade_entry_form => {:short_identifier => NEW_SHORT_IDENTIFIER, 
                                                        :description => NEW_DESCRIPTION,
                                                        :message => NEW_MESSAGE,
                                                        :date => @grade_entry_form.date,
                                                        :grade_entry_items => [@q1]}}
        end
        should assign_to :grade_entry_form
        should set_the_flash.to(I18n.t('grade_entry_forms.edit.success'))
        should respond_with :redirect
        
        should "verify that the property values were actually updated" do
          g = GradeEntryForm.find(@grade_entry_form.id)
          assert_equal NEW_SHORT_IDENTIFIER, g.short_identifier
          assert_equal NEW_DESCRIPTION, g.description
          assert_equal NEW_MESSAGE, g.message
          assert_equal [@q1], g.grade_entry_items
        end
      end
      
      context ":edit with valid properties, including multiple GradeEntryItems" do 
        setup do
          post_as @admin, :edit, {:id => @grade_entry_form.id, 
                                  :grade_entry_form => {:short_identifier => NEW_SHORT_IDENTIFIER, 
                                                        :description => NEW_DESCRIPTION,
                                                        :message => NEW_MESSAGE,
                                                        :date => @grade_entry_form.date,
                                                        :grade_entry_items => [@q1, @q2, @q3]}}
        end
        should assign_to :grade_entry_form
        should set_the_flash.to(I18n.t('grade_entry_forms.edit.success'))
        should respond_with :redirect
        
        should "verify that the property values were actually updated" do
          g = GradeEntryForm.find(@grade_entry_form.id)
          assert_equal NEW_SHORT_IDENTIFIER, g.short_identifier
          assert_equal NEW_DESCRIPTION, g.description
          assert_equal NEW_MESSAGE, g.message
          assert_equal [@q1, @q2, @q3], g.grade_entry_items
        end
      end
      
      context ":edit with missing GradeEntryItem name" do 
        setup do
          @q1.name = ""
          post_as @admin, :edit, {:id => @grade_entry_form.id, 
                                  :grade_entry_form => {:short_identifier => NEW_SHORT_IDENTIFIER, 
                                                        :description => NEW_DESCRIPTION,
                                                        :message => NEW_MESSAGE,
                                                        :date => @grade_entry_form.date,
                                                        :grade_entry_items => [@q1, @q2]}}
        end
        should assign_to :grade_entry_form
        should respond_with :success
        
        should "verify that the error message made it to the response" do
          assert_match Regexp.new(Regexp.escape(I18n.t('grade_entry_forms.blank_field'))), @response.body
        end
        
        should "verify that the property values were not updated" do
          g = GradeEntryForm.find(@grade_entry_form.id)
          assert_equal @original.short_identifier, g.short_identifier
          assert_equal @original.description, g.description
          assert_equal @original.message, g.message
          assert_equal [], g.grade_entry_items
        end
      end
      
      context ":edit with invalid GradeEntryItem out_of" do 
        setup do
          @q1.out_of = -10
          post_as @admin, :edit, {:id => @grade_entry_form.id, 
                                  :grade_entry_form => {:short_identifier => NEW_SHORT_IDENTIFIER, 
                                                        :description => NEW_DESCRIPTION,
                                                        :message => NEW_MESSAGE,
                                                        :date => @grade_entry_form.date,
                                                        :grade_entry_items => [@q1, @q2]}}
        end
        should assign_to :grade_entry_form
        should respond_with :success
        
        should "verify that the error message made it to the response" do
          assert_match Regexp.new(I18n.t('grade_entry_forms.invalid_column_out_of')), @response.body
        end
        
        should "verify that the property values were not updated" do
          g = GradeEntryForm.find(@grade_entry_form.id)
          assert_equal @original.short_identifier, g.short_identifier
          assert_equal @original.description, g.description
          assert_equal @original.message, g.message
          assert_equal @original.grade_entry_items, g.grade_entry_items
        end
      end
      
      context ":edit with zero-value GradeEntryItem out_of" do 
        setup do
          @q1.out_of = 0
          post_as @admin, :edit, {:id => @grade_entry_form.id, 
                                  :grade_entry_form => {:short_identifier => NEW_SHORT_IDENTIFIER, 
                                                        :description => NEW_DESCRIPTION,
                                                        :message => NEW_MESSAGE,
                                                        :date => @grade_entry_form.date,
                                                        :grade_entry_items => [@q1, @q2]}}
        end
        should assign_to :grade_entry_form
        should set_the_flash.to(I18n.t('grade_entry_forms.edit.success'))
        should respond_with :redirect
        
        should "verify that the property values were actually updated" do
          g = GradeEntryForm.find(@grade_entry_form.id)
          assert_equal NEW_SHORT_IDENTIFIER, g.short_identifier
          assert_equal NEW_DESCRIPTION, g.description
          assert_equal NEW_MESSAGE, g.message
          assert_equal [@q1, @q2], g.grade_entry_items
        end
      end
      
      
      context ":edit with duplicate GradeEntryItem name" do 
        setup do
          @grade_entry_form_with_dup = GradeEntryForm.make
          @q1.name = "Q1"
          @q2.name = "Q1"
          @grade_entry_form_with_dup.grade_entry_items.make(:name => @q1.name)
          @grade_entry_form_before = @grade_entry_form_with_dup
          
          post_as @admin, :edit, {:id => @grade_entry_form_with_dup.id, 
                                  :grade_entry_form => {:short_identifier => NEW_SHORT_IDENTIFIER, 
                                                        :description => NEW_DESCRIPTION,
                                                        :message => NEW_MESSAGE,
                                                        :date => @grade_entry_form_with_dup.date,
                                                        :grade_entry_items => [@q1, @q2]}}
          @grade_entry_form_before.reload
        end
        should assign_to :grade_entry_form
        should respond_with :success
        
        should "verify that the error message made it to the response" do
          assert_match Regexp.new(I18n.t('grade_entry_forms.invalid_name')), @response.body
        end
        
        should "verify that the property values were not updated" do
          g = GradeEntryForm.find(@grade_entry_form_with_dup.id)
          assert_equal @grade_entry_form_before.short_identifier, g.short_identifier
          assert_equal @grade_entry_form_before.description, g.description
          assert_equal @grade_entry_form_before.message, g.message
          assert_equal @grade_entry_form_before.grade_entry_items, g.grade_entry_items
        end
      end
    end
    
    # Test updating grades
    context "POST on :update_grade when the Grade has an existing value - " do 
      setup do
        @grade_entry_items = @grade_entry_form_with_grade_entry_items.grade_entry_items
        @grade_entry_student_with_some_grades = @grade_entry_form_with_grade_entry_items.grade_entry_students.make
        @grade_entry_student_with_some_grades.grades.make(:grade_entry_item => @grade_entry_items[0], 
                                                          :grade => 3)
        @grade_entry_student_with_some_grades.grades.make(:grade_entry_item => @grade_entry_items[1], 
                                                          :grade => 7)
      end
      
      context "change the existing value to a valid value" do
        setup do
          @new_grade = 4
          post_as @admin, :update_grade, {:grade_entry_item_id => @grade_entry_items[0].id,
                                          :student_id => @grade_entry_student_with_some_grades.user_id,
                                          :updated_grade => @new_grade,
                                          :id => @grade_entry_form_with_grade_entry_items.id}
        end
        should assign_to :grade
        should render_template :update_grade
        should respond_with :success
        should "verify that the grade was actually updated" do
          grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student_with_some_grades.id,
                                                                               @grade_entry_items[0].id)
          assert_equal @new_grade, grade.grade
        end
      end
      
      context "attempt to change the existing value to a string" do
        setup do
          @new_grade = "abc"
          @original_grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student_with_some_grades.id,
                                                                                         @grade_entry_items[0].id).grade
          post_as @admin, :update_grade, {:grade_entry_item_id => @grade_entry_items[0].id,
                                          :student_id => @grade_entry_student_with_some_grades.user_id,
                                          :updated_grade => @new_grade,
                                          :id => @grade_entry_form_with_grade_entry_items.id}
        end
        should assign_to :grade
        should render_template :update_grade
        should respond_with :success
        should "verify that the grade was not updated" do
          grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student_with_some_grades.id,
                                                                               @grade_entry_items[0].id)
          assert_equal @original_grade, grade.grade
        end
      end
      
      context "attempt to change the value of an existing grade to a negative number" do
        setup do
          @new_grade = -5
          @original_grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student_with_some_grades.id,
                                                                                         @grade_entry_items[0].id).grade
          post_as @admin, :update_grade, {:grade_entry_item_id => @grade_entry_items[0].id,
                                          :student_id => @grade_entry_student_with_some_grades.user_id,
                                          :updated_grade => @new_grade,
                                          :id => @grade_entry_form_with_grade_entry_items.id}
        end
        should assign_to :grade
        should render_template :update_grade
        should respond_with :success
        should "verify that the grade was not updated" do
          grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student_with_some_grades.id,
                                                                               @grade_entry_items[0].id)
          assert_equal @original_grade, grade.grade
        end
      end
    end
    
    context "POST on :update_grade when the Grade does not have an existing value and the GradeEntryStudent does exist - " do
      setup do
        @grade_entry_items = @grade_entry_form_with_grade_entry_items.grade_entry_items
        @grade_entry_student = @grade_entry_form_with_grade_entry_items.grade_entry_students.make
      end
      
      context "set an empty grade to a valid value" do
        setup do
          @new_grade = 2.5
          post_as @admin, :update_grade, {:grade_entry_item_id => @grade_entry_items[0].id,
                                          :student_id => @grade_entry_student.user_id,
                                          :updated_grade => @new_grade,
                                          :id => @grade_entry_form_with_grade_entry_items.id}
        end
        should assign_to :grade
        should render_template :update_grade
        should respond_with :success
        should "verify that the grade was actually created" do
          grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student.id,
                                                                               @grade_entry_items[0].id)
          assert_equal @new_grade, grade.grade
        end
      end
      
      context "attempt to set an empty grade to a string" do
        setup do
          @new_grade = "abc"
          post_as @admin, :update_grade, {:grade_entry_item_id => @grade_entry_items[0].id,
                                          :student_id => @grade_entry_student.user_id,
                                          :updated_grade => @new_grade,
                                          :id => @grade_entry_form_with_grade_entry_items.id}
        end
        should assign_to :grade
        should render_template :update_grade
        should respond_with :success
        should "verify that the grade's value was not set" do
          grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student.id,
                                                                               @grade_entry_items[0].id)
          assert_nil grade.grade
        end
      end
      
      context "attempt to set an empty grade to a negative number" do
        setup do
          @new_grade = -7
          post_as @admin, :update_grade, {:grade_entry_item_id => @grade_entry_items[0].id,
                                          :student_id => @grade_entry_student.user_id,
                                          :updated_grade => @new_grade,
                                          :id => @grade_entry_form_with_grade_entry_items.id}
        end
        should assign_to :grade
        should render_template :update_grade
        should respond_with :success
        should "verify that the grade's value was not set" do
          grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student.id,
                                                                               @grade_entry_items[0].id)                                                                    
          assert_nil grade.grade
        end
      end
    end
    
    context "POST on :update_grade when the Grade does not have an existing value and the GradeEntryStudent does not exist - " do
      setup do
        @grade_entry_items = @grade_entry_form_with_grade_entry_items.grade_entry_items
        @student = Student.make
      end
      
      context "set an empty grade to a valid value" do
        setup do
          @new_grade = 2.5
          post_as @admin, :update_grade, {:grade_entry_item_id => @grade_entry_items[0].id,
                                          :student_id => @student.id,
                                          :updated_grade => @new_grade,
                                          :id => @grade_entry_form_with_grade_entry_items.id}
        end
        should assign_to :grade
        should render_template :update_grade
        should respond_with :success
        should "verify that the GradeEntryStudent and Grade were actually created" do
          grade_entry_student = GradeEntryStudent.find_by_user_id(@student.id)
          assert_not_nil grade_entry_student
          grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(grade_entry_student.id,
                                                                               @grade_entry_items[0].id)
          assert_equal @new_grade, grade.grade
        end   
      end
      
      context "attempt to set an empty grade to a string" do
        setup do
          @new_grade = "abc"
          post_as @admin, :update_grade, {:grade_entry_item_id => @grade_entry_items[0].id,
                                          :student_id => @student.id,
                                          :updated_grade => @new_grade,
                                          :id => @grade_entry_form_with_grade_entry_items.id}
        end
        should assign_to :grade
        should render_template :update_grade
        should respond_with :success
        should "verify that the Grade's value was not set" do
          grade_entry_student = GradeEntryStudent.find_by_user_id(@student.id)
          grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(grade_entry_student.id, @grade_entry_items[0].id)
          assert_nil grade.grade
        end
      end
      
      context "attempt to set an empty grade to a negative number" do
        setup do
          @new_grade = -7
          post_as @admin, :update_grade, {:grade_entry_item_id => @grade_entry_items[0].id,
                                          :student_id => @student.id,
                                          :updated_grade => @new_grade,
                                          :id => @grade_entry_form_with_grade_entry_items.id}
        end
        should assign_to :grade
        should render_template :update_grade
        should respond_with :success
        should "verify that the Grade's value was not set" do
          grade_entry_student = GradeEntryStudent.find_by_user_id(@student.id)
          grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(grade_entry_student.id, @grade_entry_items[0].id)
          assert_nil grade.grade
        end
      end
    end
    
    # Test g_table_paginate
    context "POST on :g_table_paginate " do
      setup do
        get_as @admin, :grades, :id => @grade_entry_form.id
        post_as @admin, :g_table_paginate, {:id => @grade_entry_form.id,
                                            :alpha_category => "J-K",
                                            :filter => "none",
                                            :sort_by => "last_name",
                                            :page => 1,
                                            :update_alpha_pagination_options => "true",
                                            :per_page => 15,
                                            :desc => "false"}
      end
      should assign_to :alpha_pagination_options
      should assign_to :students
      should assign_to :alpha_category
      should render_template :g_table_paginate
      should respond_with :success
    end

    # Test releasing/unreleasing the marks
    context "POST on :update_grade_entry_students: " do 
      setup do
        last_names = ["Albert", "Alwyn", "Auric", "Berio", "Bliss", "Bridge", "Britten", "Cage", 
                      "Dukas", "Duparc", "Egge", "Feldman"]
        @grade_entry_form1 = make_grade_entry_form_with_multiple_grade_entry_items
        @students = []
        @specific_students = []
        (0..11).each do |i|
          student = Student.make(:user_name => "s" + i.to_s, :last_name => last_names[i], :first_name => "Bob")
          @students << student
          @grade_entry_form1.grade_entry_students.make(:user => student)
        end
      end
      
      context "release the marks for particular students" do
        setup do
          @specific_students = [@students[0].id, @students[1].id, @students[2].id]
          post_as @admin, :update_grade_entry_students, {:students => @specific_students,
                                                         :filter => 'none',
                                                         :ap_select_full => false,
                                                         :release_results => true,
                                                         :id => @grade_entry_form1.id}
        end
        should respond_with :redirect
        should "verify that the released_to_student attribute was set to true for the specified students" do
          (0..2).each do |i|
            grade_entry_student = GradeEntryStudent.find_by_user_id(@students[i].id)
            assert_equal true, grade_entry_student.released_to_student
          end
        end
        
        should "verify that the released_to_student attribute was not set to true for the other students" do
          (3..(@students.size-1)).each do |i|
            grade_entry_student = GradeEntryStudent.find_by_user_id(@students[i].id)
            assert_equal false, grade_entry_student.released_to_student
          end
        end
      end
      
      context "release the marks for all of the students" do
        setup do
          (0..(@students.size-1)).each do |i|
            @specific_students << @students[i].id
          end
          post_as @admin, :update_grade_entry_students, {:students => @specific_students,
                                                         :filter => 'none',
                                                         :ap_select_full => true,
                                                         :release_results => true,
                                                         :id => @grade_entry_form1.id}
        end
        should respond_with :redirect
        should "verify that the released_to_student attribute was set to true for all of the students" do
          (0..(@specific_students.size-1)).each do |i|
            grade_entry_student = GradeEntryStudent.find_by_user_id(@students[i].id)
            assert_equal true, grade_entry_student.released_to_student
          end
        end
      end
      
      context "unrelease the marks for particular students" do
        setup do
          @specific_students = [@students[0].id, @students[1].id, @students[2].id]
          post_as @admin, :update_grade_entry_students, {:students => @specific_students,
                                                         :filter => 'none',
                                                         :ap_select_full => false,
                                                         :unrelease_results => false,
                                                         :id => @grade_entry_form1.id}
        end
        should respond_with :redirect
        should "verify that the released_to_student attribute was set to false" do
          (0..2).each do |i|
            grade_entry_student = GradeEntryStudent.find_by_user_id(@students[i].id)
            assert_equal false, grade_entry_student.released_to_student
          end
        end
      end
      
      context "unrelease the marks for all of the students" do
        setup do
          (0..(@students.size-1)).each do |i|
            @specific_students << @students[i].id
          end
          post_as @admin, :update_grade_entry_students, {:students => @specific_students,
                                                         :filter => 'none',
                                                         :ap_select_full => true,
                                                         :unrelease_results => true,
                                                         :id => @grade_entry_form1.id}
        end
        should respond_with :redirect
        should "verify that the released_to_student attribute was set to false for all of the students" do
          (0..(@specific_students.size-1)).each do |i|
            grade_entry_student = GradeEntryStudent.find_by_user_id(@students[i].id)
            assert_equal false, grade_entry_student.released_to_student
          end
        end
      end
    end
  end
end
