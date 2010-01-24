require File.dirname(__FILE__) + '/authenticated_controller_test'
require 'shoulda'

class NoteControllerTest < AuthenticatedControllerTest

  fixtures :all
  
  # Security test - these should all fail
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
    
    context "GET on :index" do
      setup do
        get_as @student, :index
      end
      should_respond_with :missing
    end
    
    context "GET on :new" do
      setup do
        get_as @student, :new
      end
      should_respond_with :missing
    end
    
    context "POST on :create" do
      setup do
        post_as @student, :create
      end
      should_respond_with :missing
    end
    
    context "GET on :new_update_groupings" do
      setup do
        get_as @student, :new_update_groupings
      end
      should_respond_with :missing
    end
    
    context "GET on :edit" do
      setup do
        get_as @student, :edit
      end
      should_respond_with :missing
    end
    
    context "POST on :update" do
      setup do
        post_as @student, :update
      end
      should_respond_with :missing
    end
    
    context "DELETE on :delete" do
      setup do
        get_as @student, :delete
      end
      should_respond_with :missing
    end
  end # student context
  
  context "An authenticated and authorized TA doing a " do
    setup do
      @assignment = assignments(:assignment_1)
      @grouping = groupings(:grouping_1)
      @controller_to = 'groups'
      @action_to = 'manage'
      @message = "This is a note"
      @ta = users(:ta1)
    end
    
    context "GET on :notes_dialog" do
      setup do
        get_as @ta, :notes_dialog, :id => @assignment.id, :noteable_type => 'Grouping', :noteable_id => @grouping.id, :controller_to => @controller_to, :action_to => @action_to 
      end
      should_respond_with :success
    end
    
    context "POST on :add_notes" do
      setup do
        post_as @ta, :add_note, :new_notes => @message, :noteable_type => 'Grouping', :noteable_id => @grouping.id, :controller_to => @controller_to, :action_to => @action_to
      end
      should_redirect_to("groups manage page") { url_for(:controller => @controller_to, :action => @action_to, :success => true) }
    end
    
    context "GET on :index" do
      setup do
        get_as @ta, :index
      end
      should_respond_with :success
      should_render_template 'index.html.erb'
    end
    
    context "GET on :new" do
      setup do
        get_as @ta, :new
      end
      should_respond_with :success
      should_render_template 'new.html.erb'
    end
    
    context "POST on :create" do
      context "with empty note" do
        setup do
          post_as @ta, :create, { :note => {:noteable_id => @grouping.id} }
        end
        should_assign_to :note
        should_not_set_the_flash
        should_assign_to :assignments, :groupings
        should_render_template 'new.html.erb'
      end
      
      context "with good data" do
        setup do
          post_as @ta, :create, { :note => {:noteable_id => @grouping.id, :notes_message => @message} }
        end
        should_assign_to :note
        should_set_the_flash_to I18n.t('notes.create.success')
        should_redirect_to("notes index page") { url_for(:controller => "note") }
        should_change("the number of notes", :by => 1) { Note.count }
      end
    end
    
    context "GET on :new_update_groupings" do
      setup do
        get_as @ta, :new_update_groupings, :assignment_id => @assignment.id
      end
      should_respond_with :success
      should_render_template 'new_update_groupings.rjs'
    end
    
    context "GET on :edit" do
      context "for a note belonging to itself" do
        setup do
          @note = notes(:note_2)
          get_as @ta, :edit, { :id => @note.id }
        end
        should_respond_with :success
        should_render_template 'edit.html.erb'
      end
      
      context "for a note belonging to someone else" do
        setup do
          @note = notes(:note_1)
          get_as @ta, :edit, { :id => @note.id }
        end
        should_respond_with :missing
      end
    end

    context "POST on :update" do
      context "for a note belonging to itself" do
        context "with bad data" do
          setup do
            @note = notes(:note_2)
            post_as @ta, :update, { :id => @note.id, :note => {:notes_message => ''} }
          end
          should_assign_to :note
          should_not_set_the_flash
          should_render_template 'edit.html.erb'
        end
        
        context "with good data" do
          setup do
            @note = notes(:note_2)
            @new_message = "Changed message"
            post_as @ta, :update, { :id => @note.id, :note => {:notes_message => @new_message} }
          end
          should_assign_to :note
          should_set_the_flash_to I18n.t('notes.update.success')
          should_redirect_to("notes index") { url_for(:controller => "note") }
        end
      end
      
      context "for a note belonging to someone else" do
        setup do
          @note = notes(:note_1)
          @new_message = "Changed message"
          post_as @ta, :update, { :id => @note.id, :note => {:notes_message => @new_message} }
        end
        should_respond_with :missing
      end
    end
    
    context "DELETE on :delete" do
      context "for a note belonging to itself" do
        setup do
          @note = notes(:note_2)
          delete_as @ta, :delete, {:id => @note.id}
        end
        should_assign_to :note
        should_set_the_flash_to I18n.t('notes.delete.success')
      end
      
      context "for a note belonging to someone else" do
        setup do
          @note = notes(:note_1)
          delete_as @ta, :delete, {:id => @note.id}
        end
        should_assign_to :note
        should_set_the_flash_to I18n.t('notes.delete.error_permissions')
      end
    end
  end # TA context
  
  context "An authenticated and authorized admin doing a " do
    setup do
      @assignment = assignments(:assignment_1)
      @grouping = groupings(:grouping_1)
      @controller_to = 'groups'
      @action_to = 'manage'
      @message = "This is a note"
      @admin = users(:olm_admin_1)
    end
    
    context "GET on :notes_dialog" do
      setup do
        get_as @admin, :notes_dialog, :id => @assignment.id, :noteable_type => 'Grouping', :noteable_id => @grouping.id, :controller_to => @controller_to, :action_to => @action_to 
      end
      should_respond_with :success
    end
    
    context "POST on :add_notes" do
      setup do
        post_as @admin, :add_note, :new_notes => @message, :noteable_type => 'Grouping', :noteable_id => @grouping.id, :controller_to => @controller_to, :action_to => @action_to
      end
      should_redirect_to("groups manage page") { url_for(:controller => @controller_to, :action => @action_to, :success => true) }
    end
    
    context "GET on :index" do
      setup do
        get_as @admin, :index
      end
      should_respond_with :success
    end
    
    context "GET on :new" do
      setup do
        get_as @admin, :new
      end
      should_respond_with :success
    end
    
    context "POST on :create" do
      context "with empty note" do
        setup do
          post_as @admin, :create, { :note => {:noteable_id => @grouping.id} }
        end
        should_assign_to :note
        should_not_set_the_flash
        should_assign_to :assignments, :groupings
        should_render_template 'new.html.erb'
      end
      
      context "with good data" do
        setup do
          post_as @admin, :create, { :note => {:noteable_id => @grouping.id, :notes_message => @message} }
        end
        should_assign_to :note
        should_set_the_flash_to I18n.t('notes.create.success')
        should_redirect_to("notes index page") { url_for(:controller => "note") }
        should_change("the number of notes", :by => 1) { Note.count }
      end
    end
    
    context "GET on :new_update_groupings" do
      setup do
        get_as @admin, :new_update_groupings, :assignment_id => @assignment.id
      end
      should_respond_with :success
      should_render_template 'new_update_groupings.rjs'
    end
    
    context "GET on :edit" do
      context "for a note belonging to itself" do
        setup do
          @note = notes(:note_1)
          get_as @admin, :edit, { :id => @note.id }
        end
        should_respond_with :success
        should_render_template 'edit.html.erb'
      end
      
      context "for a note belonging to someone else" do
        setup do
          @note = notes(:note_2)
          get_as @admin, :edit, { :id => @note.id }
        end
        should_respond_with :success
        should_render_template 'edit.html.erb'
      end
    end
    
    context "POST on :update" do
      context "for a note belonging to itself" do
        context "with bad data" do
          setup do
            @note = notes(:note_2)
            post_as @admin, :update, { :id => @note.id, :note => {:notes_message => ''} }
          end
          should_assign_to :note
          should_not_set_the_flash
          should_render_template 'edit.html.erb'
        end
        
        context "with good data" do
          setup do
            @note = notes(:note_1)
            @new_message = "Changed message"
            post_as @admin, :update, { :id => @note.id, :note => {:notes_message => @new_message} }
          end
          should_assign_to :note
          should_set_the_flash_to I18n.t('notes.update.success')
          should_redirect_to("notes index") { url_for(:controller => "note") }
        end
      end
      
      context "for a note belonging to someone else" do
        setup do
          @note = notes(:note_2)
          @new_message = "Changed message"
          post_as @admin, :update, { :id => @note.id, :note => {:notes_message => @new_message} }
        end
        should_assign_to :note
        should_set_the_flash_to I18n.t('notes.update.success')
        should_redirect_to("notes index") { url_for(:controller => "note") }
      end
    end
    
    context "DELETE on :delete" do
      context "for a note belonging to itself" do
        setup do
          @note = notes(:note_1)
          delete_as @admin, :delete, {:id => @note.id}
        end
        should_assign_to :note
        should_set_the_flash_to I18n.t('notes.delete.success')
      end
      
      context "for a note belonging to someone else" do
        setup do
          @note = notes(:note_2)
          delete_as @admin, :delete, {:id => @note.id}
        end
        should_assign_to :note
        should_set_the_flash_to I18n.t('notes.delete.success')
      end
    end
  end # admin context
  
end
