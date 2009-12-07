require File.dirname(__FILE__) + '/authenticated_controller_test'
require 'shoulda'

class GradeEntryFormsControllerTest < AuthenticatedControllerTest
  fixtures :grade_entry_forms, :users
  
  # Constants for :edit tests
  NEW_SHORT_IDENTIFIER = "NewSI"
  NEW_DESCRIPTION = "NewDescription"
  NEW_MESSAGE = "NewMessage"
  NEW_DATE = 3.days.from_now
  
  # An authenticated and authorized student
  context "An authenticated and authorized student doing a " do
    setup do
      @student = users(:student1)
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
  end
  
  # An authenitcated and authorized TA
  context "An authenticated and authorized TA doing a " do
    setup do
      @ta = users(:ta1)
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
      @admin = users(:olm_admin_1)
      @grade_entry_form = grade_entry_forms(:grade_entry_form_1)
      @original = @grade_entry_form
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
        @original = @grade_entry_form
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
        @grade_entry_form_2 = grade_entry_forms(:grade_entry_form_2)
        @original_2 = @grade_entry_form_2
        @grade_entry_item1 = grade_entry_items(:grade_entry_item_1)
        @grade_entry_item2 = grade_entry_items(:grade_entry_item_2)
        @grade_entry_item3 = grade_entry_items(:grade_entry_item_3)
        @q1 = GradeEntryItem.new(:name => @grade_entry_item1.name, :out_of => @grade_entry_item1.out_of)
        @q2 = GradeEntryItem.new(:name => @grade_entry_item2.name, :out_of => @grade_entry_item2.out_of)
        @q3 = GradeEntryItem.new(:name => @grade_entry_item3.name, :out_of => @grade_entry_item3.out_of)
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
          post_as @admin, :edit, {:id => @grade_entry_form_2.id, 
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
          g = GradeEntryForm.find(@grade_entry_form_2.id)
          assert_equal NEW_SHORT_IDENTIFIER, g.short_identifier
          assert_equal NEW_DESCRIPTION, g.description
          assert_equal NEW_MESSAGE, g.message
          assert_equal [@q1], g.grade_entry_items
        end
      end
      
      context ":edit with valid properties, including multiple GradeEntryItems" do 
        setup do
          post_as @admin, :edit, {:id => @grade_entry_form_2.id, 
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
          g = GradeEntryForm.find(@grade_entry_form_2.id)
          assert_equal NEW_SHORT_IDENTIFIER, g.short_identifier
          assert_equal NEW_DESCRIPTION, g.description
          assert_equal NEW_MESSAGE, g.message
          assert_equal [@q1, @q2, @q3], g.grade_entry_items
        end
      end
      
      context ":edit with missing GradeEntryItem name" do 
        setup do
          @q1.name = ""
          post_as @admin, :edit, {:id => @grade_entry_form_2.id, 
                                  :grade_entry_form => {:short_identifier => NEW_SHORT_IDENTIFIER, 
                                                        :description => NEW_DESCRIPTION,
                                                        :message => NEW_MESSAGE,
                                                        :date => @grade_entry_form_2.date,
                                                        :grade_entry_items => [@q1, @q2]}}
        end
        should_assign_to :grade_entry_form
        should_respond_with :success
        
        should "verify that the error message made it to the response" do
          assert_match Regexp.new(I18n.t('grade_entry_forms.blank_field')), @response.body
        end
        
        should "verify that the property values were not updated" do
          g = GradeEntryForm.find(@grade_entry_form_2.id)
          assert_equal @original_2.short_identifier, g.short_identifier
          assert_equal @original_2.description, g.description
          assert_equal @original_2.message, g.message
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
          @q2.name = @q1.name
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
          assert_match Regexp.new(I18n.t('grade_entry_forms.invalid_name')), @response.body
        end
        
        should "verify that the property values were not updated" do
          g = GradeEntryForm.find(@grade_entry_form.id)
          assert_equal @original.short_identifier, g.short_identifier
          assert_equal @original.description, g.description
          assert_equal @original.message, g.message
          assert_equal @original.grade_entry_items, g.grade_entry_items
        end
      end
    end
  end
end
