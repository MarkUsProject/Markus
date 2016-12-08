# test using MACHINIST

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'blueprints'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__), 'authenticated_controller_test'))
require 'shoulda'

class NotesControllerTest < AuthenticatedControllerTest

  # Security test - these should all fail
  context 'An authenticated and authorized student doing a ' do
    setup do
      @student = Student.make
    end

    should 'get on notes_dialog' do
      get_as @student, :notes_dialog, id: 1
      assert_response :missing
    end

    should ' on notes_dialog' do
      post_as @student, :notes_dialog, id: 1
      assert_response :missing
    end

    should 'GET on :add_note' do
      get_as @student, :add_note
      assert_response :missing
    end

    should 'POST on :add_note' do
      post_as @student, :add_note
      assert_response :missing
    end

    should 'GET on :index' do
      get_as @student, :index
      assert_response :missing
    end

    should 'GET on :new' do
      get_as @student, :new
      assert_response :missing
    end

    should 'POST on :create' do
      post_as @student, :create
      assert_response :missing
    end

    should 'GET on :new_update_groupings' do
      get_as @student, :new_update_groupings
      assert_response :missing
    end

    should 'GET on :edit' do
      get_as @student, :edit, id: 1
      assert_response :missing
    end

    should 'POST on :update' do
      put_as @student, :update, id: 1
      assert_response :missing
    end

    should 'DELETE on :destroy' do
      delete_as @student, :destroy, id: 1
      assert_response :missing
    end
  end # student context

  context 'An authenticated and authorized TA doing a ' do
    setup do
      @assignment = Assignment.make
      @grouping = Grouping.make(assignment:@assignment)
      @controller_to = 'groups'
      @action_to = 'manage'
      @message = 'This is a note'
      @ta = Ta.make
    end

    should 'be able to get :notes_dialog' do
      get_as @ta,
              :notes_dialog,
              id: @assignment.id,
              noteable_type: 'Grouping',
              noteable_id: @grouping.id,
              controller_to: @controller_to,
              action_to: @action_to
      assert_response :success
    end

    should 'be able to add new notes with a valid note' do
      post_as @ta,
              :add_note,
              new_notes: @message,
              noteable_type: 'Grouping',
              noteable_id: @grouping.id,
              controller_to: @controller_to,
              action_to: @action_to
      assert render_template 'note/modal_dialogs/notes_dialog_success.js.erb'
    end

    should 'be able to add new notes with an invalid note' do
      post_as @ta,
              :add_note,
              new_notes: '',
              noteable_type: 'Grouping',
              noteable_id: @grouping.id,
              controller_to: @controller_to,
              action_to: @action_to
      assert render_template 'note/modal_dialogs/notes_dialog_error.js.erb'
    end

    should 'get index, with a note' do
      @note = @note = Note.make( creator_id: @ta.id )
      get_as @ta, :index
      assert_response :success
      assert render_template 'index.html.erb'
    end

    should 'get :new' do
      get_as @ta, :new
      assert_response :success
      assert render_template 'new.html.erb'
    end

    context 'POST on :create' do
      should 'be able to create with empty note' do
        post_as @ta,
                :create,
                {noteable_type: 'Grouping',
                 note: {noteable_id: @grouping.id}}
        assert_not_nil assigns :note
        assert_equal true, flash.empty?
        assert_not_nil assigns :assignments
        assert_not_nil assigns :groupings
        assert render_template 'new.html.erb'
      end

      # We wrap the machinist calls in anonymous functions in order to delay
      # the creation of the DB records. This way we make sure that the "make"
      # calls are actually executed when we want them to execute, not when the
      # test cases are initially processed. The machinist calls can't run
      # earlier, since the DB will get cleared prior each test. Hence, if we
      # wouldn't do this trick, we had no records in the database to refer to
      # when we need them.
      {Grouping: lambda {Grouping.make},
       Student: lambda {Student.make},
       Assignment: lambda {Assignment.make}}.each_pair do |type, noteable|

        should "with good #{type.to_s} data" do
          @notes = Note.count
          post_as @ta,
                  :create,
                  {noteable_type: type.to_s,
                   note: {noteable_id: noteable.call().id,
                             notes_message: @message}}
          assert_not_nil assigns :note
          assert_equal flash[:success], [I18n.t('notes.create.success')]
          assert redirect_to(controller: 'note')
          assert_equal(@notes + 1,  Note.count )
        end
      end
    end

    should 'be able to update new groupings' do
      get_as @ta, :new_update_groupings, assignment_id: @assignment.id
      assert_response :success
      assert render_template 'new_update_groupings.js.erb'
    end

    context 'GET on :noteable_object_selector' do
      should 'for Groupings' do
        get_as @ta, :noteable_object_selector, noteable_type: 'Grouping'
        assert_not_nil assigns :assignments
        assert_not_nil assigns :groupings
        assert_response :success
        assert render_template 'noteable_object_selector.js.erb'
      end

      should 'for Students' do
        get_as @ta, :noteable_object_selector, noteable_type: 'Student'
        assert_not_nil assigns :students
        assert_response :success
        assert render_template 'noteable_object_selector.js.erb'
      end

      should 'for Assignments' do
        get_as @ta, :noteable_object_selector, noteable_type: 'Assignment'
        assert_not_nil assigns :assignments
        assert_response :success
        assert render_template 'noteable_object_selector.js.erb'
      end
    end

    context 'GET on :edit' do
      should 'for a note belonging to themselves (get as TA)' do
        @note = Note.make(creator_id: @ta.id)
        get_as @ta, :edit, {id: @note.id}
        assert_response :success
        assert render_template 'edit.html.erb'
      end

      should 'for a note belonging to someone else (get as TA)' do
        @note = Note.make
        get_as @ta, :edit, {id: @note.id}
        assert_response :missing
      end
    end

    context 'POST on :update' do
      context 'for a note belonging to themselves' do
        should 'with bad data' do
          @note = Note.make(creator_id: @ta.id)
          post_as @ta,
                  :update,
                  {id: @note.id,
                   note: {notes_message: ''}}
          assert_not_nil assigns :note
          assert_equal true, flash.empty?
          assert render_template 'edit.html.erb'
        end

        should 'with good data' do
          @note = Note.make(creator_id: @ta.id )
          @new_message = 'Changed message'
          post_as @ta,
                  :update,
                  {id: @note.id,
                   note: {notes_message: @new_message}}
          assert_not_nil assigns :note
          assert_equal flash[:success], [I18n.t('notes.update.success')]
          assert redirect_to(controller: 'note')
        end
      end

      should 'for a note belonging to someone else (post as TA)' do
        @note = Note.make
        @new_message = 'Changed message'
        post_as @ta,
                :update,
                {id: @note.id,
                 note: {notes_message: @new_message}}
        assert_response :missing
      end
    end

    context 'DELETE on :destroy' do
      should 'for a note belonging to themselves' do
        @note = Note.make( creator_id: @ta.id )
        delete_as @ta, :destroy, id: @note.id
        assert_not_nil assigns :note
        assert_equal flash[:success], [I18n.t('notes.delete.success')]
      end

      should 'for a note belonging to someone else (delete as TA)' do
        @note = Note.make
        delete_as @ta,
                  :destroy,
                  id: @note.id
        assert_not_nil assigns :note
        assert_equal flash[:error], [I18n.t('notes.delete.error_permissions')]
      end
    end
  end # TA context

  context 'An authenticated and authorized admin doing a ' do
    setup do
      @admin = Admin.make
    end

    should 'be able to get the index' do
      get_as @admin, :index
      assert_response :success
      assert render_template 'index.html.erb'
    end

    should 'to go on new' do
      get_as @admin, :new
      assert_response :success
    end

    should 'for Students' do
      get_as @admin, :noteable_object_selector, noteable_type: 'Student'
      assert_not_nil assigns :students
      assert_nil assigns(:assignments)
      assert_nil assigns(:groupings)
      assert_response :success
      assert render_template 'noteable_object_selector.js.erb'
    end

    should 'for Assignments' do
      get_as @admin,
              :noteable_object_selector,
              noteable_type: 'Assignment'
      assert_not_nil assigns :assignments
      assert_nil assigns(:students)
      assert_nil assigns :groupings
      assert_response :success
      assert render_template 'noteable_object_selector.js.erb'
    end

    should 'for invalid type' do
      get_as @admin, :noteable_object_selector, noteable_type: 'gibberish'
      assert_equal flash[:error], [I18n.t('notes.new.invalid_selector')]
      assert_not_nil assigns :assignments
      assert_not_nil assigns :groupings
      assert_nil assigns :students
      assert_response :success
      assert render_template 'noteable_object_selector.js.erb'
    end

    context 'with an assignment' do
      setup do
        @grouping = Grouping.make
        @assignment = @grouping.assignment
        @controller_to = 'groups'
        @action_to = 'manage'
        @message = 'This is a note'
      end

      should 'GET on :notes_dialog' do
        get_as @admin,
              :notes_dialog,
              id: @assignment.id,
              noteable_type: 'Grouping',
              noteable_id: @grouping.id,
              controller_to: @controller_to,
              action_to: @action_to
        assert_response :success
      end

      should 'with a valid note' do
        post_as @admin,
                :add_note,
                new_notes: @message,
                noteable_type: 'Grouping',
                noteable_id: @grouping.id,
                controller_to: @controller_to,
                action_to: @action_to
        assert render_template 'note/modal_dialogs/notes_dialog_success.js.erb'
      end

      should 'with an invalid note' do
        post_as @admin,
                :add_note,
                new_notes: '',
                noteable_type: 'Grouping',
                noteable_id: @grouping.id,
                controller_to: @controller_to,
                action_to: @action_to
        assert render_template 'note/modal_dialogs/notes_dialog_error.js.erb'
      end

      should 'with empty note' do
        post_as @admin,
                :create,
                {noteable_type: 'Grouping',
                  note: {noteable_id: @grouping.id}}
        assert_not_nil assigns :note
        assert_equal true, flash.empty?
        assert_not_nil assigns :assignments
        assert_not_nil assigns :groupings
        assert_nil assigns(:students)
        assert render_template 'new.html.erb'
      end


      {Grouping: lambda {Grouping.make},
      Student: lambda {Student.make},
      Assignment: lambda {Assignment.make} }.each_pair do |type, noteable|

        should "with good #{type.to_s} data" do
          @notes = Note.count
          post_as @admin,
                  :create,
                  {noteable_type: type.to_s,
                    note: {noteable_id: noteable.call().id,
                              notes_message: @message}}
          assert_not_nil assigns :note
          assert_equal flash[:success], [I18n.t('notes.create.success')]
          assert redirect_to(controller: 'note')
          assert_equal(@notes + 1,  Note.count )
        end
      end

      should 'GET on :new_update_groupings' do
        get_as @admin, :new_update_groupings, assignment_id: @assignment.id
        assert_response :success
        assert render_template 'new_update_groupings.js.erb'
      end

      should 'for Groupings' do
        get_as @admin, :noteable_object_selector, noteable_type: 'Grouping'
        assert_not_nil assigns :assignments
        assert_not_nil assigns :groupings
        assert_nil assigns(:students)
        assert_response :success
        assert render_template 'noteable_object_selector.js.erb'
      end

      should 'for a note belonging to themselves (get as Admin)' do
        @note = Note.make(creator_id: @admin.id)
        get_as @admin, :edit, {id: @note.id}
        assert_response :success
        assert render_template 'edit.html.erb'
      end

      should 'for a note belonging to someone else (get as Admin)' do
        @note = Note.make( creator_id: Ta.make.id  )
        get_as @admin, :edit, {id: @note.id}
        assert_response :success
        assert render_template 'edit.html.erb'
      end

      should 'with bad data' do
        @note = Note.make(creator_id: @admin.id)
        post_as @admin,
                :update, {id: @note.id, note: {notes_message: ''}}
        assert_not_nil assigns :note
        assert_equal true, flash.empty?
        assert render_template 'edit.html.erb'
      end

      should 'with good data' do
        @note = Note.make( creator_id: @admin.id  )
        @new_message = 'Changed message'
        post_as @admin,
                :update,
                {id: @note.id,
                  note: {notes_message: @new_message}}
        assert_not_nil assigns :note
        assert_equal flash[:success], [I18n.t('notes.update.success')]
        assert redirect_to(controller: 'note')
      end

      should 'for a note belonging to someone else (post as Admin)' do
        @note = Note.make( creator_id: Ta.make.id  )
        @new_message = 'Changed message'
        post_as @admin,
                :update,
                {id: @note.id, note: {notes_message: @new_message}}
        assert_not_nil assigns :note
        assert_equal flash[:success], [I18n.t('notes.update.success')]
        assert redirect_to(controller: 'note')
      end

      should 'for a note belonging to themselves (delete as Admin)' do
        @note = Note.make( creator_id: @admin.id  )
        delete_as @admin, :destroy, {id: @note.id}
        assert_not_nil assigns :note
        assert_equal flash[:success], [I18n.t('notes.delete.success')]
      end

      should 'for a note belonging to someone else (delete as Admin)' do
        @note = Note.make(creator_id: Ta.make.id)
        delete_as @admin, :destroy, {id: @note.id}
        assert_not_nil assigns :note
        assert_equal flash[:success], [I18n.t('notes.delete.success')]
      end

      should 'have noteable options for selection when viewing noteable_type Grouping' do
        @note = Note.make( creator_id: @admin.id )
        post_as @admin,
        :create,
        {noteable_type: 'Grouping',
          note: {noteable_id: @note.id,
                    notes_message: @message}}
        assert_select 'select#note_noteable_id'
      end

      should 'have noteable options for selection when viewing noteable_type Student' do
        @note = Note.make( creator_id: @admin.id )
        post_as @admin,
        :create,
        {noteable_type: 'Student',
          note: {noteable_id: @note.id,
                    notes_message: @message}}
        assert_select 'select#note_noteable_id'
      end

      should 'have noteable options for selection when viewing noteable_type Assignment' do
        @note = Note.make( creator_id: @admin.id )
        post_as @admin,
        :create,
        {noteable_type: 'Assignment',
          note: {noteable_id: @note.id,
                    notes_message: @message}}
        assert_select 'select#note_noteable_id'
      end
    end
  end # admin context
end
