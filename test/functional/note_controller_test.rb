# test using MACHINIST

require File.dirname(__FILE__) + '/../test_helper'
require File.join(File.dirname(__FILE__), '/../blueprints/blueprints')
require File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper')
require File.dirname(__FILE__) + '/authenticated_controller_test'
require 'shoulda'

class NoteControllerTest < AuthenticatedControllerTest

  def setup
    clear_fixtures
  end

  # Security test - these should all fail
  context "An authenticated and authorized student doing a " do
    setup do
      @student = Student.make
    end

    context "GET on :notes_dialog" do
      setup do
        get_as @student, :notes_dialog
      end
      should respond_with :missing
    end

    context "POST on :notes_dialog" do
      setup do
        post_as @student, :notes_dialog
      end
      should respond_with :missing
    end

    context "GET on :add_note" do
      setup do
        get_as @student, :add_note
      end
      should respond_with :missing
    end

    context "POST on :add_note" do
      setup do
        post_as @student, :add_note
      end
      should respond_with :missing
    end

    context "GET on :index" do
      setup do
        get_as @student, :index
      end
      should respond_with :missing
    end

    context "GET on :new" do
      setup do
        get_as @student, :new
      end
      should respond_with :missing
    end

    context "POST on :create" do
      setup do
        post_as @student, :create
      end
      should respond_with :missing
    end

    context "GET on :new_update_groupings" do
      setup do
        get_as @student, :new_update_groupings
      end
      should respond_with :missing
    end

    context "GET on :edit" do
      setup do
        get_as @student, :edit
      end
      should respond_with :missing
    end

    context "POST on :update" do
      setup do
        post_as @student, :update
      end
      should respond_with :missing
    end

    context "DELETE on :delete" do
      setup do
        get_as @student, :delete
      end
      should respond_with :missing
    end
  end # student context

  context "An authenticated and authorized TA doing a " do
    setup do
      @assignment = Assignment.make
      @grouping = Grouping.make(:assignment =>@assignment)
      @controller_to = 'groups'
      @action_to = 'manage'
      @message = "This is a note"
      @ta = Ta.make
    end

    context "GET on :notes_dialog" do
      setup do
        get_as @ta, :notes_dialog, :id => @assignment.id, :noteable_type => 'Grouping', :noteable_id => @grouping.id, :controller_to => @controller_to, :action_to => @action_to
      end
      should respond_with :success
    end

    context "POST on :add_notes" do
      context "with a valid note" do
        setup do
          post_as @ta, :add_note, :new_notes => @message, :noteable_type => 'Grouping', :noteable_id => @grouping.id, :controller_to => @controller_to, :action_to => @action_to
        end
        should render_template 'note/modal_dialogs/notes_dialog_success.rjs'
      end
      context "with an invalid note" do
        setup do
          post_as @ta, :add_note, :new_notes => '', :noteable_type => 'Grouping', :noteable_id => @grouping.id, :controller_to => @controller_to, :action_to => @action_to
        end
        should render_template 'note/modal_dialogs/notes_dialog_error.rjs'
      end
    end

    context "GET on :index" do
      setup do
        @note = @note = Note.make( :creator_id => @ta.id )
        get_as @ta, :index
      end
      should respond_with :success
      should render_template 'index.html.erb'
    end

    context "GET on :new" do
      setup do
        get_as @ta, :new
      end
      should respond_with :success
      should render_template 'new.html.erb'
    end

    context "POST on :create" do
      context "with empty note" do
        setup do
          post_as @ta, :create, { :noteable_type => 'Grouping' ,:note => {:noteable_id => @grouping.id} }
        end
        should assign_to :note
        should_not set_the_flash
        should assign_to :assignments
        should assign_to :groupings
        should render_template 'new.html.erb'
      end

      # We wrap the machinist calls in anonymous functions in order to delay the creation of the DB records.
      # This way we make sure that the "make" calls are actually executed when we want them to execute,
      # not when the test cases are initially processed. The machinist calls can't run earlier,
      # since the DB will get cleared prior each test. Hence, if we wouldn't do this trick,
      # we had no records in the database to refer to when we need them.
      {:Grouping => lambda {Grouping.make}, :Student => lambda {Student.make} ,:Assignment => lambda {Assignment.make} }.each_pair do |type, noteable|
        context "with good #{type.to_s} data" do
          setup do
	    @notes = Note.count
            post_as @ta, :create, { :noteable_type => type.to_s, :note => {:noteable_id => noteable.call().id, :notes_message => @message} }
          end
          should assign_to :note
          should set_the_flash.to(I18n.t('notes.create.success'))
          should redirect_to("notes index page") { url_for(:controller => "note") }
          should "Change the number of notes by 1" do
	    assert_equal(@notes + 1,  Note.count )
	  end
        end
      end
    end

    context "GET on :new_update_groupings" do
      setup do
        get_as @ta, :new_update_groupings, :assignment_id => @assignment.id
      end
      should respond_with :success
      should render_template 'new_update_groupings.rjs'
    end

    context "GET on :noteable_object_selector" do
      context "for Groupings" do
        setup do
          get_as @ta, :noteable_object_selector, :noteable_type => 'Grouping'
        end
        should assign_to :assignments
        should assign_to :groupings
        should respond_with :success
        should render_template 'noteable_object_selector.rjs'
      end

      context "for Students" do
        setup do
          get_as @ta, :noteable_object_selector, :noteable_type => 'Student'
        end
        should assign_to :students
        should respond_with :success
        should render_template 'noteable_object_selector.rjs'
      end

      context "for Assignments" do
        setup do
          get_as @ta, :noteable_object_selector, :noteable_type => 'Assignment'
        end
        should assign_to :assignments
        should respond_with :success
        should render_template 'noteable_object_selector.rjs'
      end
    end

    context "GET on :edit" do
      context "for a note belonging to themselves" do
        setup do
          @note = Note.make( :creator_id => @ta.id )
          get_as @ta, :edit, { :id => @note.id }
        end
        should respond_with :success
        should render_template 'edit.html.erb'
      end

      context "for a note belonging to someone else" do
        setup do
          @note = Note.make
          get_as @ta, :edit, { :id => @note.id }
        end
        should respond_with :missing
      end
    end

    context "POST on :update" do
      context "for a note belonging to themselves" do
        context "with bad data" do
          setup do
            @note = Note.make( :creator_id => @ta.id )
            post_as @ta, :update, { :id => @note.id, :note => {:notes_message => ''} }
          end
          should assign_to :note
          should_not set_the_flash
          should render_template 'edit.html.erb'
        end

        context "with good data" do
          setup do
            @note = Note.make( :creator_id => @ta.id  )
            @new_message = "Changed message"
            post_as @ta, :update, { :id => @note.id, :note => {:notes_message => @new_message} }
          end
          should assign_to :note
          should set_the_flash.to(I18n.t('notes.update.success'))
          should redirect_to("notes index") { url_for(:controller => "note") }
        end
      end

      context "for a note belonging to someone else" do
        setup do
          @note = Note.make
          @new_message = "Changed message"
          post_as @ta, :update, { :id => @note.id, :note => {:notes_message => @new_message} }
        end
        should respond_with :missing
      end
    end

    context "DELETE on :delete" do
      context "for a note belonging to themselves" do
        setup do
          @note = Note.make( :creator_id => @ta.id )
          delete_as @ta, :delete, {:id => @note.id}
        end
        should assign_to :note
        should set_the_flash.to(I18n.t('notes.delete.success'))
      end

      context "for a note belonging to someone else" do
        setup do
          @note = Note.make
          delete_as @ta, :delete, {:id => @note.id}
        end
        should assign_to :note
        should set_the_flash.to(I18n.t('notes.delete.error_permissions'))
      end
    end
  end # TA context

  context "An authenticated and authorized admin doing a " do
    setup do
      @grouping = Grouping.make
      @assignment = @grouping.assignment
      @controller_to = 'groups'
      @action_to = 'manage'
      @message = "This is a note"
      @admin = Admin.make
    end

    context "GET on :notes_dialog" do
      setup do
        get_as @admin, :notes_dialog, :id => @assignment.id, :noteable_type => 'Grouping', :noteable_id => @grouping.id, :controller_to => @controller_to, :action_to => @action_to
      end
      should respond_with :success
    end

    context "POST on :add_notes" do
      context "with a valid note" do
        setup do
          post_as @admin, :add_note, :new_notes => @message, :noteable_type => 'Grouping', :noteable_id => @grouping.id, :controller_to => @controller_to, :action_to => @action_to
        end
        should render_template 'note/modal_dialogs/notes_dialog_success.rjs'
      end
      context "with an invalid note" do
        setup do
          post_as @admin, :add_note, :new_notes => '', :noteable_type => 'Grouping', :noteable_id => @grouping.id, :controller_to => @controller_to, :action_to => @action_to
        end
        should render_template 'note/modal_dialogs/notes_dialog_error.rjs'
      end
    end


    context "GET on :index" do
      setup do
        get_as @admin, :index
      end
      should respond_with :success
      should render_template 'index.html.erb'
    end

    context "GET on :new" do
      setup do
        get_as @admin, :new
      end
      should respond_with :success
    end

    context "POST on :create" do
      context "with empty note" do
        setup do
          post_as @admin, :create, { :noteable_type => 'Grouping', :note => {:noteable_id => @grouping.id} }
        end
        should assign_to :note
        should_not set_the_flash
        should assign_to :assignments
        should assign_to :groupings
        should_not assign_to :students
        should render_template 'new.html.erb'
      end


     {:Grouping => lambda {Grouping.make}, :Student => lambda {Student.make} ,:Assignment => lambda {Assignment.make} }.each_pair do |type, noteable|
        context "with good #{type.to_s} data" do
          setup do
	    @notes = Note.count
            post_as @admin, :create, { :noteable_type => type.to_s, :note => {:noteable_id => noteable.call().id, :notes_message => @message} }
          end
          should assign_to :note
          should set_the_flash.to(I18n.t('notes.create.success'))
          should redirect_to("notes index page") { url_for(:controller => "note") }
          should "Change the number of notes by 1" do
	    assert_equal(@notes + 1,  Note.count )
	  end
        end
      end
    end

    context "GET on :new_update_groupings" do
      setup do
        get_as @admin, :new_update_groupings, :assignment_id => @assignment.id
      end
      should respond_with :success
      should render_template 'new_update_groupings.rjs'
    end

    context "GET on :noteable_object_selector" do
      context "for Groupings" do
        setup do
          get_as @admin, :noteable_object_selector, :noteable_type => 'Grouping'
        end
        should assign_to :assignments
        should assign_to :groupings
        should_not assign_to :students
        should respond_with :success
        should render_template 'noteable_object_selector.rjs'
      end

      context "for Students" do
        setup do
          get_as @admin, :noteable_object_selector, :noteable_type => 'Student'
        end
        should assign_to :students
        should_not assign_to :assignments
        should_not assign_to :groupings
        should respond_with :success
        should render_template 'noteable_object_selector.rjs'
      end

      context "for Assignments" do
        setup do
          get_as @admin, :noteable_object_selector, :noteable_type => 'Assignment'
        end
        should assign_to :assignments
        should_not assign_to :students
        should_not assign_to :groupings
        should respond_with :success
        should render_template 'noteable_object_selector.rjs'
      end

      context "for invalid type" do
        setup do
          get_as @admin, :noteable_object_selector, :noteable_type => 'gibberish'
        end
        should set_the_flash.to(I18n.t('notes.new.invalid_selector'))
        should assign_to :assignments
        should assign_to :groupings
        should_not assign_to :students
        should respond_with :success
        should render_template 'noteable_object_selector.rjs'
      end
    end

    context "GET on :edit" do
      context "for a note belonging to themselves" do
        setup do
          @note = Note.make( :creator_id => @admin.id  )
          get_as @admin, :edit, { :id => @note.id }
        end
        should respond_with :success
        should render_template 'edit.html.erb'
      end

      context "for a note belonging to someone else" do
        setup do
          @note = Note.make( :creator_id => Ta.make.id  )
          get_as @admin, :edit, { :id => @note.id }
        end
        should respond_with :success
        should render_template 'edit.html.erb'
      end
    end

    context "POST on :update" do
      context "for a note belonging to themselves" do
        context "with bad data" do
          setup do
            @note = Note.make( :creator_id => @admin.id  )
            post_as @admin, :update, { :id => @note.id, :note => {:notes_message => ''} }
          end
          should assign_to :note
          should_not set_the_flash
          should render_template 'edit.html.erb'
        end

        context "with good data" do
          setup do
            @note = Note.make( :creator_id => @admin.id  )
            @new_message = "Changed message"
            post_as @admin, :update, { :id => @note.id, :note => {:notes_message => @new_message} }
          end
          should assign_to :note
          should set_the_flash.to(I18n.t('notes.update.success'))
          should redirect_to("notes index") { url_for(:controller => "note") }
        end
      end

      context "for a note belonging to someone else" do
        setup do
          @note = Note.make( :creator_id => Ta.make.id  )
          @new_message = "Changed message"
          post_as @admin, :update, { :id => @note.id, :note => {:notes_message => @new_message} }
        end
        should assign_to :note
        should set_the_flash.to(I18n.t('notes.update.success'))
        should redirect_to("notes index") { url_for(:controller => "note") }
      end
    end

    context "DELETE on :delete" do
      context "for a note belonging to themselves" do
        setup do
          @note = Note.make( :creator_id => @admin.id  )
          delete_as @admin, :delete, {:id => @note.id}
        end
        should assign_to :note
        should set_the_flash.to(I18n.t('notes.delete.success'))
      end

      context "for a note belonging to someone else" do
        setup do
          @note = Note.make( :creator_id => Ta.make.id  )
          delete_as @admin, :delete, {:id => @note.id}
        end
        should assign_to :note
        should set_the_flash.to(I18n.t('notes.delete.success'))
      end
    end
  end # admin context

end
