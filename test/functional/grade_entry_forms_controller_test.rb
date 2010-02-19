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
    end
    
    # Students are not allowed to create or edit grade entry form properties
    context "GET on :new" do
      setup do
        get_as @student, :new
      end
      should_respond_with :missing
    end
    
    context "GET on :edit" do
      setup do
        get_as @student, :edit, :id => 1
      end
      should_respond_with :missing
    end
    
    context "GET on :grades" do
      setup do
        get_as @student, :grades, :id => 1
      end
      should_respond_with :missing
    end
    
    context "POST on :new" do
      setup do
        post_as @student, :new
      end
      should_respond_with :missing
    end
    
    context "POST on :edit" do
      setup do
        post_as @student, :edit, :id => 1
      end
      should_respond_with :missing
    end
    
    context "POST on :grades" do
      setup do
        post_as @student, :grades, :id => 1
      end
      should_respond_with :missing
    end
  end
  
  # An authenitcated and authorized TA
  context "An authenticated and authorized TA doing a " do
    setup do
      @ta = Ta.make
    end
    
    # TAs are not allowed to create or edit grade entry form properties
    context "GET on :new" do
      setup do
        get_as @ta, :new
      end
      should_respond_with :missing
    end
    
    context "GET on :edit" do
      setup do
        get_as @ta, :edit, :id => 1
      end
      should_respond_with :missing
    end
    
    context "POST on :new" do
      setup do
        post_as @ta, :new 
      end
      should_respond_with :missing
    end
    
    context "POST on :edit" do
      setup do
        post_as @ta, :edit
      end
      should_respond_with :missing
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
      should_assign_to :grade_entry_form
      should_render_template :new
      should_respond_with :success
      should_not_set_the_flash
    end
    
    context "GET on :edit" do 
      setup do
        get_as @admin, :edit, :id => @grade_entry_form.id
      end
      should_assign_to :grade_entry_form
      should_render_template :edit
      should_respond_with :success
      should_not_set_the_flash
    end
    
    context "GET on :grades when there are no grade entry items" do 
      setup do
        get_as @admin, :grades, :id => @grade_entry_form.id
      end
      should_assign_to :grade_entry_form
      should_render_template :grades
      should_respond_with :success
      should "verify that the no_grade_entry_items message made it to the response" do
        assert_match Regexp.new(I18n.t('grade_entry_forms.grades.no_grade_entry_items_message')), @response.body
      end
    end
    
    context "GET on :grades when there are grade entry items" do 
      setup do
        get_as @admin, :grades, :id => @grade_entry_form_with_grade_entry_items.id
      end
      should_assign_to :grade_entry_form
      should_render_template :grades
      should_respond_with :success 
    end
    
    # Test valid and invalid values for basic properties for :new
    context "POST on :new with basic valid properties" do 
      setup do
        post_as @admin, :new, {:grade_entry_form => {:short_identifier => "NT", 
                                                     :description => @grade_entry_form.description,
                                                     :message => @grade_entry_form.message,
                                                     :date => @grade_entry_form.date}}
      end
      should_assign_to :grade_entry_form
      should_set_the_flash_to I18n.t('grade_entry_forms.create.success')
      should_respond_with :redirect
    end
    
    context "POST on :new with a missing required value" do 
      setup do
        post_as @admin, :new, {:grade_entry_form => {:short_identifier => "", 
                                                     :description => @grade_entry_form.description,
                                                     :message => @grade_entry_form.message,
                                                     :date => @grade_entry_form.date}}
      end
      should_assign_to :grade_entry_form
      should "verify that the error message made it to the response" do
        assert_match Regexp.new(I18n.t('grade_entry_forms.blank_field')), @response.body
      end
      should_respond_with :success
    end
   
    context "POST on :new with an invalid basic value" do 
      setup do
        post_as @admin, :new, {:id => @grade_entry_form.id, 
                               :grade_entry_form => {:short_identifier => "NT", 
                                                     :description => @grade_entry_form.description,
                                                     :message => @grade_entry_form.message,
                                                     :date => "abcd"}}
      end
      should_assign_to :grade_entry_form
      should "verify that the error message made it to the response" do
        assert_match Regexp.new(I18n.t('grade_entry_forms.invalid_date')), @response.body
      end
      should_respond_with :success
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
      should_assign_to :grade_entry_form
      should_set_the_flash_to I18n.t('grade_entry_forms.edit.success')
      should_respond_with :redirect
      
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
      should_assign_to :grade_entry_form
      should_respond_with :success
      
      should "verify that the error message made it to the response" do
        assert_match Regexp.new(I18n.t('grade_entry_forms.blank_field')), @response.body
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
      should_assign_to :grade_entry_form
      should_respond_with :success
      
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
        should_assign_to :grade_entry_form
        should_set_the_flash_to I18n.t('grade_entry_forms.create.success')
        should_respond_with :redirect
      end
    
      context ":new with valid properties, including multiple GradeEntryItems" do 
        setup do
          post_as @admin, :new, {:grade_entry_form => {:short_identifier => "NT", 
                                                       :description => @grade_entry_form.description,
                                                       :message => @grade_entry_form.message,
                                                       :date => @grade_entry_form.date,
                                                       :grade_entry_items => [@q1, @q2, @q3]}}
        end
        should_assign_to :grade_entry_form
        should_set_the_flash_to I18n.t('grade_entry_forms.create.success')
        should_respond_with :redirect
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
        should_assign_to :grade_entry_form
        should "verify that the error message made it to the response" do
          assert_match Regexp.new(I18n.t('grade_entry_forms.blank_field')), @response.body
        end
        should_respond_with :success
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
        should_assign_to :grade_entry_form
        should "verify that the error message made it to the response" do
          assert_match Regexp.new(I18n.t('grade_entry_forms.invalid_column_out_of')), @response.body
        end
        should_respond_with :success
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
        should_assign_to :grade_entry_form
        should "verify that the error message made it to the response" do
          assert_match Regexp.new(I18n.t('grade_entry_forms.invalid_column_out_of')), @response.body
        end
        should_respond_with :success
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
        should_assign_to :grade_entry_form
        should_set_the_flash_to I18n.t('grade_entry_forms.edit.success')
        should_respond_with :redirect
        
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
        should_assign_to :grade_entry_form
        should_set_the_flash_to I18n.t('grade_entry_forms.edit.success')
        should_respond_with :redirect
        
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
        should_assign_to :grade_entry_form
        should_respond_with :success
        
        should "verify that the error message made it to the response" do
          assert_match Regexp.new(I18n.t('grade_entry_forms.blank_field')), @response.body
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
        should_assign_to :grade_entry_form
        should_respond_with :success
        
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
        should_assign_to :grade_entry_form
        should_respond_with :success
        
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
        end
        should_assign_to :grade_entry_form
        should_respond_with :success
        
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
        should_assign_to :grade
        should_render_template :update_grade
        should_respond_with :success
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
        should_assign_to :grade
        should_render_template :update_grade
        should_respond_with :success
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
        should_assign_to :grade
        should_render_template :update_grade
        should_respond_with :success
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
        should_assign_to :grade
        should_render_template :update_grade
        should_respond_with :success
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
        should_assign_to :grade
        should_render_template :update_grade
        should_respond_with :success
        should "verify that the grade was not created" do
          grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student.id,
                                                                               @grade_entry_items[0].id)
          assert_nil grade
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
        should_assign_to :grade
        should_render_template :update_grade
        should_respond_with :success
        should "verify that the grade was not created" do
          grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(@grade_entry_student.id,
                                                                               @grade_entry_items[0].id)                                                                    
          assert_nil grade
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
        should_assign_to :grade
        should_render_template :update_grade
        should_respond_with :success
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
        should_assign_to :grade
        should_render_template :update_grade
        should_respond_with :success
        should "verify that the Grade was not created" do
          grade_entry_student = GradeEntryStudent.find_by_user_id(@student.id)
          grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(grade_entry_student.id, @grade_entry_items[0].id)
          assert_nil grade
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
        should_assign_to :grade
        should_render_template :update_grade
        should_respond_with :success
        should "verify that the Grade was not created" do
          grade_entry_student = GradeEntryStudent.find_by_user_id(@student.id)
          grade = Grade.find_by_grade_entry_student_id_and_grade_entry_item_id(grade_entry_student.id, @grade_entry_items[0].id)
          assert_nil grade
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
      should_assign_to :alpha_pagination_options, :students, :alpha_category
      should_render_template :g_table_paginate
      should_respond_with :success
    end
  end
end
