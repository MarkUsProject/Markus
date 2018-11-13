describe NotesController do

  # Security test - these it all fail
  context 'An authenticated and authorized student doing a ' do
    before :each do
      @student = create(:student)
    end

    it 'get on notes_dialog' do
      get_as @student, :notes_dialog, params: { id: 1 }
      expect(response.status).to eq 404
    end

    it ' on notes_dialog' do
      post_as @student, :notes_dialog, params: { id: 1 }
      expect(response.status).to eq 404
    end

    it 'GET on :add_note' do
      get_as @student, :add_note
      expect(response.status).to eq 404
    end

    it 'POST on :add_note' do
      post_as @student, :add_note
      expect(response.status).to eq 404
    end

    it 'GET on :index' do
      get_as @student, :index
      expect(response.status).to eq 404
    end

    it 'GET on :new' do
      get_as @student, :new
      expect(response.status).to eq 404
    end

    it 'POST on :create' do
      post_as @student, :create
      expect(response.status).to eq 404
    end

    it 'GET on :new_update_groupings' do
      get_as @student, :new_update_groupings
      expect(response.status).to eq 404
    end

    it 'GET on :edit' do
      get_as @student, :edit, params: { id: 1 }
      expect(response.status).to eq 404
    end

    it 'POST on :update' do
      put_as @student, :update, params: { id: 1 }
      expect(response.status).to eq 404
    end

    it 'DELETE on :destroy' do
      delete_as @student, :destroy, params: { id: 1 }
      expect(response.status).to eq 404
    end
  end # student context

  context 'An authenticated and authorized TA doing a ' do
    before :each do
      @assignment = create(:assignment)
      @grouping = create(:grouping, assignment:@assignment)
      @controller_to = 'groups'
      @action_to = 'manage'
      @message = 'This is a note'
      @ta = create(:ta)
    end

    it 'be able to get :notes_dialog' do
      get_as @ta,
             :notes_dialog,
             params: { id: @assignment.id, noteable_type: 'Grouping', noteable_id: @grouping.id,
                       controller_to: @controller_to, action_to: @action_to }
      expect(response.status).to eq 200
    end

    it 'be able to add new notes with a valid note' do
      post_as @ta,
              :add_note,
              params: { new_notes: @message, noteable_type: 'Grouping', noteable_id: @grouping.id,
                        controller_to: @controller_to, action_to: @action_to }
      expect(response).to render_template('notes/modal_dialogs/notes_dialog_success')
    end

    it 'be able to add new notes with an invalid note' do
      post_as @ta,
              :add_note,
              params: { new_notes: '', noteable_type: 'Grouping', noteable_id: @grouping.id,
                        controller_to: @controller_to, action_to: @action_to }
      expect(response).to render_template('notes/modal_dialogs/notes_dialog_error')
    end

    it 'get index, with a note' do
      @note = @note = create(:note, creator_id: @ta.id )
      get_as @ta, :index
      expect(response.status).to eq 200
      expect(response).to render_template('notes/index')
    end

    it 'get :new' do
      get_as @ta, :new
      expect(response.status).to eq 200
      expect(response).to render_template('notes/new')
    end

    context 'POST on :create' do
      it 'be able to create with empty note' do
        post_as @ta,
                :create,
                params: { noteable_type: 'Grouping', note: { noteable_id: @grouping.id } }
        expect(assigns :note).not_to be_nil
        expect(flash.empty?).to be_truthy
        expect(assigns :assignments).not_to be_nil
        expect(assigns :groupings).not_to be_nil
        expect(response).to render_template('notes/new')
      end

      it 'with good Grouping data' do
        grouping = create(:grouping)
        @notes = Note.count
        post_as @ta,
                :create,
                params: { noteable_type: 'Grouping', note: { noteable_id: grouping.id, notes_message: @message } }
        expect(assigns :note).not_to be_nil
        expect(flash[:success].map { |f| extract_text f }).to eq [I18n.t('notes.create.success')].map { |f| extract_text f }
        expect(response).to redirect_to(controller: 'notes')
        expect(Note.count).to eq @notes + 1
      end

      it 'with good Student data' do
        student = create(:student)
        @notes = Note.count
        post_as @ta,
                :create,
                params: { noteable_type: 'Student', note: { noteable_id: student.id, notes_message: @message } }
        expect(assigns :note).not_to be_nil
        expect(flash[:success].map { |f| extract_text f }).to eq [I18n.t('notes.create.success')].map { |f| extract_text f }
        expect(response).to redirect_to(controller: 'notes')
        expect(Note.count).to eq @notes + 1
      end

      it 'with good Assignment data' do
        assignment = create(:assignment)
        @notes = Note.count
        post_as @ta,
                :create,
                params: { noteable_type: 'Assignment', note: { noteable_id: assignment.id, notes_message: @message } }
        expect(assigns :note).not_to be_nil
        expect(flash[:success].map { |f| extract_text f }).to eq [I18n.t('notes.create.success')].map { |f| extract_text f }
        expect(response).to redirect_to(controller: 'notes')
        expect(Note.count).to eq @notes + 1
      end
    end

    it 'be able to update new groupings' do
      get_as @ta, :new_update_groupings, params: { assignment_id: @assignment.id }
      expect(response.status).to eq 200
      expect(response).to render_template('notes/new_update_groupings')
    end

    context 'GET on :noteable_object_selector' do
      it 'for Groupings' do
        get_as @ta, :noteable_object_selector, params: { noteable_type: 'Grouping' }
        expect(assigns :assignments).not_to be_nil
        expect(assigns :groupings).not_to be_nil
        expect(response.status).to eq 200
        expect(response).to render_template('notes/noteable_object_selector')
      end

      it 'for Students' do
        get_as @ta, :noteable_object_selector, params: { noteable_type: 'Student' }
        expect(assigns :students).not_to be_nil
        expect(response.status).to eq 200
        expect(response).to render_template('notes/noteable_object_selector')
      end

      it 'for Assignments' do
        get_as @ta, :noteable_object_selector, params: { noteable_type: 'Assignment' }
        expect(assigns :assignments).not_to be_nil
        expect(response.status).to eq 200
        expect(response).to render_template('notes/noteable_object_selector')
      end
    end

    context 'GET on :edit' do
      it 'for a note belonging to themselves (get as TA)' do
        @note = create(:note, creator_id: @ta.id)
        get_as @ta, :edit, params: { id: @note.id }
        expect(response.status).to eq 200
        expect(response).to render_template('notes/edit')
      end

      it 'for a note belonging to someone else (get as TA)' do
        @note = create(:note)
        get_as @ta, :edit, params: { id: @note.id }
        expect(response.status).to eq 404
      end
    end

    context 'POST on :update' do
      context 'for a note belonging to themselves' do
        it 'with bad data' do
          @note = create(:note, creator_id: @ta.id)
          post_as @ta,
                  :update,
                  params: { id: @note.id, note: { notes_message: '' } }
          expect(assigns :note).not_to be_nil
          expect(flash.empty?).to be_truthy
          expect(response).to render_template('notes/edit')
        end

        it 'with good data' do
          @note = create(:note, creator_id: @ta.id )
          @new_message = 'Changed message'
          post_as @ta,
                  :update,
                  params: { id: @note.id, note: { notes_message: @new_message } }
          expect(assigns :note).not_to be_nil
          i18t_string = [I18n.t('notes.update.success')].map { |f| extract_text f }
          expect(flash[:success].map { |f| extract_text f }).to eq(i18t_string)
          expect(response).to redirect_to(controller: 'notes')
        end
      end

      it 'for a note belonging to someone else (post as TA)' do
        @note = create(:note)
        @new_message = 'Changed message'
        post_as @ta,
                :update,
                params: { id: @note.id, note: { notes_message: @new_message } }
        expect(response.status).to eq 404
      end
    end

    context 'DELETE on :destroy' do
      it 'for a note belonging to themselves' do
        @note = create(:note, creator_id: @ta.id)
        delete_as @ta, :destroy, params: { id: @note.id }
        expect(assigns :note).not_to be_nil
        expect(flash[:success].map { |f| extract_text f }).to eq [I18n.t('notes.delete.success')].map { |f| extract_text f }
      end

      it 'for a note belonging to someone else (delete as TA)' do
        @note = create(:note)
        delete_as @ta, :destroy, params: { id: @note.id }
        expect(assigns :note).not_to be_nil
        i18t_string = [I18n.t('notes.delete.error_permissions')].map { |f| extract_text f }
        expect(flash[:error].map { |f| extract_text f }).to eq(i18t_string)
      end
    end
  end # TA context

  context 'An authenticated and authorized admin doing a ' do
    before :each do
      @admin = create(:admin)
    end

    it 'be able to get the index' do
      get_as @admin, :index
      expect(response.status).to eq 200
      expect(response).to render_template('notes/index')
    end

    it 'to go on new' do
      get_as @admin, :new
      expect(response.status).to eq 200
    end

    it 'for Students' do
      get_as @admin, :noteable_object_selector, params: { noteable_type: 'Student' }
      expect(assigns :students).not_to be_nil
      expect(assigns :assignments).to be_nil
      expect(assigns :groupings).to be_nil
      expect(response.status).to eq 200
      expect(response).to render_template('notes/noteable_object_selector')
    end

    it 'for Assignments' do
      get_as @admin, :noteable_object_selector, params: { noteable_type: 'Assignment' }
      expect(assigns :assignments).not_to be_nil
      expect(assigns :students).to be_nil
      expect(assigns :groupings).to be_nil
      expect(response.status).to eq 200
      expect(response).to render_template('notes/noteable_object_selector')
    end

    it 'for invalid type' do
      get_as @admin, :noteable_object_selector, params: { noteable_type: 'gibberish' }
      i18t_string = [I18n.t('notes.new.invalid_selector')].map { |f| extract_text f }
      expect(flash[:error].map { |f| extract_text f }).to eq(i18t_string)
      expect(assigns :assignments).not_to be_nil
      expect(assigns :groupings).not_to be_nil
      expect(assigns :students).to be_nil
      expect(response.status).to eq 200
      expect(response).to render_template('notes/noteable_object_selector')
    end

    context 'with an assignment' do
      render_views
      before :each do
        @grouping = create(:grouping)
        @student = create(:student)
        @assignment = @grouping.assignment
        @controller_to = 'groups'
        @action_to = 'manage'
        @message = 'This is a note'
      end

      it 'GET on :notes_dialog' do
        get_as @admin,
               :notes_dialog,
               params: { id: @assignment.id, noteable_type: 'Grouping', noteable_id: @grouping.id,
                         controller_to: @controller_to, action_to: @action_to }
        expect(response.status).to eq 200
      end

      it 'with a valid note' do
        post_as @admin,
                :add_note,
                params: { new_notes: @message, noteable_type: 'Grouping', noteable_id: @grouping.id,
                          controller_to: @controller_to, action_to: @action_to }
        expect(response).to render_template('notes/modal_dialogs/notes_dialog_success')
      end

      it 'with an invalid note' do
        post_as @admin,
                :add_note,
                params: { new_notes: '', noteable_type: 'Grouping', noteable_id: @grouping.id,
                          controller_to: @controller_to, action_to: @action_to }
        expect(response).to render_template('notes/modal_dialogs/notes_dialog_error')
      end

      it 'with empty note' do
        post_as @admin, :create, params: { noteable_type: 'Grouping', note: { noteable_id: @grouping.id } }
        expect(assigns :note).not_to be_nil
        expect(flash.empty?).to be_truthy
        expect(assigns :assignments).not_to be_nil
        expect(assigns :groupings).not_to be_nil
        expect(assigns :students).to be_nil
        expect(response).to render_template('notes/new')
      end

      it "with good Grouping data" do
        grouping = create(:grouping)
        @notes = Note.count
        post_as @admin,
                :create,
                params: { noteable_type: 'Grouping', note: { noteable_id: grouping.id, notes_message: @message } }
        expect(assigns :note).not_to be_nil
        expect(flash[:success].map { |f| extract_text f }).to eq [I18n.t('notes.create.success')].map { |f| extract_text f }
        expect(response).to redirect_to(controller: 'notes')
        expect(Note.count).to eq @notes + 1
      end

      it "with good Student data" do
        student = create(:student)
        @notes = Note.count
        post_as @admin,
                :create,
                params: { noteable_type: 'Student', note: { noteable_id: student.id, notes_message: @message } }
        expect(assigns :note).not_to be_nil
        expect(flash[:success].map { |f| extract_text f }).to eq [I18n.t('notes.create.success')].map { |f| extract_text f }
        expect(response).to redirect_to(controller: 'notes')
        expect(Note.count).to eq @notes + 1
      end

      it "with good Assignment data" do
        assignment = create(:assignment)
        @notes = Note.count
        post_as @admin,
                :create,
                params: { noteable_type: 'Assignment', note: { noteable_id: assignment.id, notes_message: @message } }
        expect(assigns :note).not_to be_nil
        expect(flash[:success].map { |f| extract_text f }).to eq [I18n.t('notes.create.success')].map { |f| extract_text f }
        expect(response).to redirect_to(controller: 'notes')
        expect(Note.count).to eq @notes + 1
      end

      it 'GET on :new_update_groupings' do
        get_as @admin, :new_update_groupings, params: { assignment_id: @assignment.id }
        expect(response.status).to eq 200
        expect(response).to render_template('notes/new_update_groupings')
      end

      it 'for Groupings' do
        get_as @admin, :noteable_object_selector, params: { noteable_type: 'Grouping' }
        expect(assigns :assignments).not_to be_nil
        expect(assigns :groupings).not_to be_nil
        expect(assigns :students).to be_nil
        expect(response.status).to eq 200
        expect(response).to render_template('notes/noteable_object_selector')
      end

      it 'for a note belonging to themselves (get as Admin)' do
        @note = create(:note, creator_id: @admin.id)
        get_as @admin, :edit, params: { id: @note.id }
        expect(response.status).to eq 200
        expect(response).to render_template('notes/edit')
      end

      it 'for a note belonging to someone else (get as Admin)' do
        @note = create(:note, creator_id: create(:ta).id)
        get_as @admin, :edit, params: { id: @note.id }
        expect(response.status).to eq 200
        expect(response).to render_template('notes/edit')
      end

      it 'with bad data' do
        @note = create(:note, creator_id: @admin.id)
        post_as @admin, :update, params: { id: @note.id, note: { notes_message: '' } }
        expect(assigns :note).not_to be_nil
        expect(flash.empty?).to be_truthy
        expect(response).to render_template('notes/edit')
      end

      it 'with good data' do
        @note = create(:note, creator_id: @admin.id)
        @new_message = 'Changed message'
        post_as @admin, :update, params: { id: @note.id, note: { notes_message: @new_message } }
        expect(assigns :note).not_to be_nil
        expect(flash[:success].map { |f| extract_text f }).to eq [I18n.t('notes.update.success')].map { |f| extract_text f }
        expect(response).to redirect_to(controller: 'notes')
      end

      it 'for a note belonging to someone else (post as Admin)' do
        @note = create(:note, creator_id: create(:ta).id)
        @new_message = 'Changed message'
        post_as @admin, :update, params: { id: @note.id, note: { notes_message: @new_message } }
        expect(assigns :note).not_to be_nil
        expect(flash[:success].map { |f| extract_text f }).to eq [I18n.t('notes.update.success')].map { |f| extract_text f }
        expect(response).to redirect_to(controller: 'notes')
      end

      it 'for a note belonging to themselves (delete as Admin)' do
        @note = create(:note, creator_id: @admin.id)
        delete_as @admin, :destroy, params: { id: @note.id }
        expect(assigns :note).not_to be_nil
        expect(flash[:success].map { |f| extract_text f }).to eq [I18n.t('notes.delete.success')].map { |f| extract_text f }
      end

      it 'for a note belonging to someone else (delete as Admin)' do
        @note = create(:note, creator_id: create(:ta).id)
        delete_as @admin, :destroy, params: { id: @note.id }
        expect(assigns :note).not_to be_nil
        expect(flash[:success].map { |f| extract_text f }).to eq [I18n.t('notes.delete.success')].map { |f| extract_text f }
      end

      it 'have noteable options for selection when viewing noteable_type Grouping' do
        @note = create(:note, creator_id: @admin.id)
        post_as @admin, :create, params: { noteable_type: 'Grouping', note: { noteable_id: @note.id } }
        assert_select 'select#note_noteable_id'
      end

      it 'have noteable options for selection when viewing noteable_type Student' do
        @note = create(:note, creator_id: @admin.id)
        post_as @admin, :create, params: { noteable_type: 'Student', note: {noteable_id: @note.id } }
        assert_select 'select#note_noteable_id'
      end

      it 'have noteable options for selection when viewing noteable_type Assignment' do
        @note = create(:note, creator_id: @admin.id)
        post_as @admin, :create, params: { noteable_type: 'Assignment', note: {noteable_id: @note.id } }
        assert_select 'select#note_noteable_id'
      end
    end
  end # admin context
end
