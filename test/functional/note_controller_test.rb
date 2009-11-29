require File.dirname(__FILE__) + '/authenticated_controller_test'
require 'shoulda'

class NoteControllerTest < AuthenticatedControllerTest
  fixtures :users, :assignments, :groupings
  
  context "An authenticated and authorized student doing a " do    
    setup do
      @student = users(:student1)
    end
    
    context "GET on :notes_dialog" do
      setup do
        get_as @student, :notes_dialog
      end
      should_respond_with :missing
    end
    
    context "POST on :notes_dialog" do
      setup do
        post_as @student, :notes_dialog
      end
      should_respond_with :missing
    end
    
    context "GET on :add_note" do
      setup do
        get_as @student, :add_note
      end
      should_respond_with :missing
    end
    
    context "POST on :add_note" do
      setup do
        post_as @student, :add_note
      end
      should_respond_with :missing
    end
  end
  
  context "An authenticated and authorized TA doing a " do
    setup do
      @assignment = assignments(:assignment_1)
      @grouping = groupings(:grouping_1)
      @controller_to = 'groups'
      @action_to = 'manage'
      @message = "This is a note"
      @ta = users(:ta1)
      @current_user = @ta
    end
    
    context "GET on :notes_dialog" do
      setup do
        get_as @ta, :notes_dialog, :id => @assignment.id, :noteable_type => 'Grouping', :noteable_id => @grouping.id, :controller_to => @controller_to, :action_to => @action_to 
      end
      should_respond_with :success
    end 
    
    should "POST on :add_notes" do
      post_as @ta, :add_note, :new_notes => @message, :noteable_type => 'Grouping', :noteable_id => @grouping.id, :controller_to => @controller_to, :action_to => @action_to
      assert_redirected_to :controller => @controller_to, :action => @action_to
    end
    
  end
  
  context "An authenticated and authorized admin doing a " do
    setup do
      @assignment = assignments(:assignment_1)
      @grouping = groupings(:grouping_1)
      @controller_to = 'groups'
      @action_to = 'manage'
      @message = "This is a note"
      @admin = users(:olm_admin_1)
      @current_user = @admin
    end
    
    context "GET on :notes_dialog" do
      setup do
        get_as @admin, :notes_dialog, :id => @assignment.id, :noteable_type => 'Grouping', :noteable_id => @grouping.id, :controller_to => @controller_to, :action_to => @action_to 
      end
      should_respond_with :success
    end 
    
    should "POST on :add_note" do
      post_as @admin, :add_note, :new_notes => @message, :noteable_type => 'Grouping', :noteable_id => @grouping.id, :controller_to => @controller_to, :action_to => @action_to
      assert_redirected_to :controller => @controller_to, :action => @action_to
    end
  end
  
end
