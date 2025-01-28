describe NotesController do
  # Security test - these it all fail
  context 'An authenticated and authorized student doing a' do
    let(:course) { @note.course }

    before do
      @student = create(:student)
      @note = create(:note)
    end

    it 'get on notes_dialog' do
      get_as @student, :notes_dialog, params: { course_id: course.id }
      expect(response).to have_http_status :forbidden
    end

    it 'post on notes_dialog' do
      post_as @student, :notes_dialog, params: { course_id: course.id }
      expect(response).to have_http_status :forbidden
    end

    it 'GET on :add_note' do
      get_as @student, :add_note, params: { course_id: course.id }
      expect(response).to have_http_status :forbidden
    end

    it 'POST on :add_note' do
      post_as @student, :add_note, params: { course_id: course.id }
      expect(response).to have_http_status :forbidden
    end

    it 'GET on :index' do
      get_as @student, :index, params: { course_id: course.id }
      expect(response).to have_http_status :forbidden
    end

    it 'GET on :new' do
      get_as @student, :new, params: { course_id: course.id }
      expect(response).to have_http_status :forbidden
    end

    it 'POST on :create' do
      post_as @student, :create, params: { course_id: course.id }
      expect(response).to have_http_status :forbidden
    end

    it 'GET on :new_update_groupings' do
      get_as @student, :new_update_groupings, params: { course_id: course.id }
      expect(response).to have_http_status :forbidden
    end

    it 'GET on :edit' do
      get_as @student, :edit, params: { course_id: course.id, id: @note.id }
      expect(response).to have_http_status :forbidden
    end

    it 'POST on :update' do
      put_as @student, :update, params: { course_id: course.id, id: @note.id }
      expect(response).to have_http_status :forbidden
    end

    it 'DELETE on :destroy' do
      delete_as @student, :destroy, params: { course_id: course.id, id: @note.id }
      expect(response).to have_http_status :forbidden
    end
  end

  context 'An authenticated and authorized TA doing a' do
    let(:course) { @assignment.course }

    before do
      @assignment = create(:assignment)
      @grouping = create(:grouping, assignment: @assignment)
      @controller_to = 'groups'
      @action_to = 'manage'
      @message = 'This is a note'
      @ta = create(:ta)
    end

    it 'be able to get :notes_dialog' do
      get_as @ta,
             :notes_dialog,
             params: { course_id: course.id, assignment_id: @assignment.id, noteable_type: 'Grouping',
                       noteable_id: @grouping.id, controller_to: @controller_to, action_to: @action_to }
      expect(response).to have_http_status :success
    end

    it 'be able to add new notes with a valid note' do
      post_as @ta,
              :add_note,
              params: { course_id: course.id, new_notes: @message, noteable_type: 'Grouping', noteable_id: @grouping.id,
                        controller_to: @controller_to, action_to: @action_to }
      expect(response).to have_http_status :success
    end

    it 'be able to add new notes with an invalid note' do
      post_as @ta,
              :add_note,
              params: { course_id: course.id, new_notes: '', noteable_type: 'Grouping', noteable_id: @grouping.id,
                        controller_to: @controller_to, action_to: @action_to }
      expect(response).to have_http_status :success
    end

    it 'get index, with a note' do
      @note = @note = create(:note, creator_id: @ta.id)
      get_as @ta, :index, params: { course_id: course.id }
      expect(response).to have_http_status :success
    end

    it 'get :new' do
      get_as @ta, :new, params: { course_id: course.id }
      expect(response).to have_http_status :success
    end

    it 'get request for all notes from index' do
      @note = @note = create(:note, creator_id: @ta.id)
      get_as @ta, :index, params: { course_id: course.id, format: :json }
      note_data = response.parsed_body[0]

      expect(note_data['date']).to eq(@note.format_date)
      expect(note_data['user_name']).to eq(@note.role.user_name)
      expect(note_data['message']).to eq(@note.notes_message)
      expect(note_data['display_for']).to eq(@note.noteable.display_for_note)
      # Should be true, since TA created note
      expect(note_data['modifiable']).to be(true)
    end

    context 'POST on :create' do
      it 'be able to create with empty note' do
        post_as @ta,
                :create,
                params: { course_id: course.id, noteable_type: 'Grouping', note: { noteable_id: @grouping.id } }
        expect(assigns(:note)).not_to be_nil
        expect(flash).to be_empty
        expect(assigns(:assignments)).not_to be_nil
        expect(assigns(:groupings)).not_to be_nil
      end

      it 'with good Grouping data' do
        grouping = create(:grouping)
        @notes = Note.count
        post_as @ta,
                :create,
                params: { course_id: course.id, noteable_type: 'Grouping',
                          note: { noteable_id: grouping.id, notes_message: @message } }
        expect(assigns(:note)).not_to be_nil
        expect(flash[:success]).to have_message(I18n.t('flash.actions.create.success',
                                                       resource_name: Note.model_name.human))
        expect(response).to redirect_to(controller: 'notes')
        expect(Note.count).to eq @notes + 1
      end

      it 'with good Student data' do
        student = create(:student)
        @notes = Note.count
        post_as @ta,
                :create,
                params: { course_id: course.id, noteable_type: 'Student',
                          note: { noteable_id: student.id, notes_message: @message } }
        expect(assigns(:note)).not_to be_nil
        expect(flash[:success]).to have_message(I18n.t('flash.actions.create.success',
                                                       resource_name: Note.model_name.human))
        expect(response).to redirect_to(controller: 'notes')
        expect(Note.count).to eq @notes + 1
      end

      it 'with good Assignment data' do
        assignment = create(:assignment)
        @notes = Note.count
        post_as @ta,
                :create,
                params: { course_id: course.id, noteable_type: 'Assignment',
                          note: { noteable_id: assignment.id, notes_message: @message } }
        expect(assigns(:note)).not_to be_nil
        expect(flash[:success]).to have_message(I18n.t('flash.actions.create.success',
                                                       resource_name: Note.model_name.human))
        expect(response).to redirect_to(controller: 'notes')
        expect(Note.count).to eq @notes + 1
      end

      it 'with a noteable from a different course' do
        create(:course)
        assignment = create(:assignment, course: create(:course))
        @notes = Note.count
        post_as @ta,
                :create,
                params: { course_id: course.id, noteable_type: 'Assignment',
                          note: { noteable_id: assignment.id, notes_message: @message } }
        expect(response).to have_http_status(:not_found)
        expect(Note.count).to eq @notes
      end
    end

    it 'be able to update new groupings' do
      get_as @ta, :new_update_groupings, params: { course_id: course.id, assignment_id: @assignment.id }
      expect(response).to have_http_status :ok
    end

    context 'GET on :noteable_object_selector' do
      it 'for Groupings' do
        get_as @ta, :noteable_object_selector, params: { course_id: course.id, noteable_type: 'Grouping' }
        expect(assigns(:assignments)).not_to be_nil
        expect(assigns(:groupings)).not_to be_nil
        expect(response).to have_http_status :ok
      end

      it 'for Students' do
        get_as @ta, :noteable_object_selector, params: { course_id: course.id, noteable_type: 'Student' }
        expect(assigns(:students)).not_to be_nil
        expect(response).to have_http_status :ok
      end

      it 'for Assignments' do
        get_as @ta, :noteable_object_selector, params: { course_id: course.id, noteable_type: 'Assignment' }
        expect(assigns(:assignments)).not_to be_nil
        expect(response).to have_http_status :ok
      end
    end

    context 'GET on :edit' do
      it 'for a note belonging to themselves (get as TA)' do
        @note = create(:note, creator_id: @ta.id)
        get_as @ta, :edit, params: { course_id: course.id, id: @note.id }
        expect(response).to have_http_status :ok
      end

      it 'for a note belonging to someone else (get as TA)' do
        @note = create(:note)
        get_as @ta, :edit, params: { course_id: course.id, id: @note.id }
        expect(response).to have_http_status :forbidden
      end
    end

    context 'POST on :update' do
      context 'for a note belonging to themselves' do
        it 'with bad data' do
          @note = create(:note, creator_id: @ta.id)
          post_as @ta,
                  :update,
                  params: { course_id: course.id, id: @note.id, note: { notes_message: '' } }
          expect(assigns(:note)).not_to be_nil
          expect(flash).to be_empty
        end

        it 'with good data' do
          @note = create(:note, creator_id: @ta.id)
          @new_message = 'Changed message'
          post_as @ta,
                  :update,
                  params: { course_id: course.id, id: @note.id, note: { notes_message: @new_message } }
          expect(assigns(:note)).not_to be_nil
          expect(flash[:success]).to have_message(I18n.t('flash.actions.update.success',
                                                         resource_name: Note.model_name.human))
          expect(response).to redirect_to(controller: 'notes')
        end
      end

      it 'for a note belonging to someone else (post as TA)' do
        @note = create(:note)
        @new_message = 'Changed message'
        post_as @ta,
                :update,
                params: { course_id: course.id, id: @note.id, note: { notes_message: @new_message } }
        expect(response).to have_http_status :forbidden
      end
    end

    context 'DELETE on :destroy' do
      it 'for a note belonging to themselves' do
        @note = create(:note, creator_id: @ta.id)
        delete_as @ta, :destroy, params: { course_id: course.id, id: @note.id }
        expect(assigns(:note)).not_to be_nil
        expect(flash[:success]).to have_message(I18n.t('flash.actions.destroy.success',
                                                       resource_name: Note.model_name.human))
      end

      it 'for a note belonging to someone else (delete as TA)' do
        @note = create(:note)
        delete_as @ta, :destroy, params: { course_id: course.id, id: @note.id }
        expect(assigns(:note)).not_to be_nil
        expect(flash[:error]).to have_message(I18n.t('action_policy.policy.note.modify?'))
      end
    end
  end

  context 'An authenticated and authorized instructor doing a' do
    let(:course) { @instructor.course }

    before do
      @instructor = create(:instructor)
    end

    it 'be able to get the index' do
      get_as @instructor, :index, params: { course_id: course.id }
      expect(response).to have_http_status :ok
    end

    it 'to go on new' do
      get_as @instructor, :new, params: { course_id: course.id }
      expect(response).to have_http_status :ok
    end

    it 'for Students' do
      get_as @instructor, :noteable_object_selector, params: { course_id: course.id, noteable_type: 'Student' }
      expect(assigns(:students)).not_to be_nil
      expect(assigns(:assignments)).to be_nil
      expect(assigns(:groupings)).to be_nil
      expect(response).to have_http_status :ok
    end

    it 'for Assignments' do
      get_as @instructor, :noteable_object_selector, params: { course_id: course.id, noteable_type: 'Assignment' }
      expect(assigns(:assignments)).not_to be_nil
      expect(assigns(:students)).to be_nil
      expect(assigns(:groupings)).to be_nil
      expect(response).to have_http_status :ok
    end

    it 'for invalid type' do
      get_as @instructor, :noteable_object_selector, params: { course_id: course.id, noteable_type: 'gibberish' }
      expect(flash[:error]).to have_message(I18n.t('notes.new.invalid_selector'))
      expect(assigns(:assignments)).not_to be_nil
      expect(assigns(:groupings)).not_to be_nil
      expect(assigns(:students)).to be_nil
      expect(response).to have_http_status :ok
    end

    context 'with an assignment' do
      before do
        @grouping = create(:grouping)
        @student = create(:student)
        @assignment = @grouping.assignment
        @controller_to = 'groups'
        @action_to = 'manage'
        @message = 'This is a note'
      end

      it 'GET on :notes_dialog' do
        get_as @instructor,
               :notes_dialog,
               params: { course_id: course.id, assignment_id: @assignment.id, noteable_type: 'Grouping',
                         noteable_id: @grouping.id, controller_to: @controller_to, action_to: @action_to }
        expect(response).to have_http_status :ok
      end

      it 'with a valid note' do
        post_as @instructor,
                :add_note,
                params: { course_id: course.id, new_notes: @message, noteable_type: 'Grouping',
                          noteable_id: @grouping.id, controller_to: @controller_to, action_to: @action_to }
        expect(response).to have_http_status :success
      end

      it 'with an invalid note' do
        post_as @instructor,
                :add_note,
                params: { course_id: course.id, new_notes: '', noteable_type: 'Grouping', noteable_id: @grouping.id,
                          controller_to: @controller_to, action_to: @action_to }
        expect(response).to have_http_status :success
      end

      it 'with empty note' do
        post_as @instructor, :create, params: { course_id: course.id, noteable_type: 'Grouping',
                                                note: { noteable_id: @grouping.id } }
        expect(assigns(:note)).not_to be_nil
        expect(flash).to be_empty
        expect(assigns(:assignments)).not_to be_nil
        expect(assigns(:groupings)).not_to be_nil
        expect(assigns(:students)).to be_nil
      end

      it 'with good Grouping data' do
        grouping = create(:grouping)
        @notes = Note.count
        post_as @instructor,
                :create,
                params: { course_id: course.id, noteable_type: 'Grouping',
                          note: { noteable_id: grouping.id, notes_message: @message } }
        expect(assigns(:note)).not_to be_nil
        expect(flash[:success]).to have_message(I18n.t('flash.actions.create.success',
                                                       resource_name: Note.model_name.human))
        expect(response).to redirect_to(controller: 'notes')
        expect(Note.count).to eq @notes + 1
      end

      it 'with good Student data' do
        student = create(:student)
        @notes = Note.count
        post_as @instructor,
                :create,
                params: { course_id: course.id, noteable_type: 'Student',
                          note: { noteable_id: student.id, notes_message: @message } }
        expect(assigns(:note)).not_to be_nil
        expect(flash[:success]).to have_message(I18n.t('flash.actions.create.success',
                                                       resource_name: Note.model_name.human))
        expect(response).to redirect_to(controller: 'notes')
        expect(Note.count).to eq @notes + 1
      end

      it 'with good Assignment data' do
        assignment = create(:assignment)
        @notes = Note.count
        post_as @instructor,
                :create,
                params: { course_id: course.id, noteable_type: 'Assignment',
                          note: { noteable_id: assignment.id, notes_message: @message } }
        expect(assigns(:note)).not_to be_nil
        expect(flash[:success]).to have_message(I18n.t('flash.actions.create.success',
                                                       resource_name: Note.model_name.human))
        expect(response).to redirect_to(controller: 'notes')
        expect(Note.count).to eq @notes + 1
      end

      it 'GET on :new_update_groupings' do
        get_as @instructor, :new_update_groupings, params: { course_id: course.id, assignment_id: @assignment.id }
        expect(response).to have_http_status :ok
      end

      it 'for Groupings' do
        get_as @instructor, :noteable_object_selector, params: { course_id: course.id, noteable_type: 'Grouping' }
        expect(assigns(:assignments)).not_to be_nil
        expect(assigns(:groupings)).not_to be_nil
        expect(assigns(:students)).to be_nil
        expect(response).to have_http_status :ok
      end

      it 'for a note belonging to themselves (get as Instructor)' do
        @note = create(:note, creator_id: @instructor.id)
        get_as @instructor, :edit, params: { course_id: course.id, id: @note.id }
        expect(response).to have_http_status :ok
      end

      it 'for a note belonging to someone else (get as Instructor)' do
        @note = create(:note, creator_id: create(:ta).id)
        get_as @instructor, :edit, params: { course_id: course.id, id: @note.id }
        expect(response).to have_http_status :ok
      end

      it 'with bad data' do
        @note = create(:note, creator_id: @instructor.id)
        post_as @instructor, :update, params: { course_id: course.id, id: @note.id, note: { notes_message: '' } }
        expect(assigns(:note)).not_to be_nil
        expect(flash).to be_empty
      end

      it 'with good data' do
        @note = create(:note, creator_id: @instructor.id)
        @new_message = 'Changed message'
        post_as @instructor, :update,
                params: { course_id: course.id, id: @note.id, note: { notes_message: @new_message } }
        expect(assigns(:note)).not_to be_nil
        expect(flash[:success]).to have_message(I18n.t('flash.actions.update.success',
                                                       resource_name: Note.model_name.human))
        expect(response).to redirect_to(controller: 'notes')
      end

      it 'for a note belonging to someone else (post as Instructor)' do
        @note = create(:note, creator_id: create(:ta).id)
        @new_message = 'Changed message'
        post_as @instructor, :update,
                params: { course_id: course.id, id: @note.id, note: { notes_message: @new_message } }
        expect(assigns(:note)).not_to be_nil
        expect(flash[:success]).to have_message(I18n.t('flash.actions.update.success',
                                                       resource_name: Note.model_name.human))
        expect(response).to redirect_to(controller: 'notes')
      end

      it 'for a note belonging to themselves (delete as Instructor)' do
        @note = create(:note, creator_id: @instructor.id)
        delete_as @instructor, :destroy, params: { course_id: course.id, id: @note.id }
        expect(assigns(:note)).not_to be_nil
        expect(flash[:success]).to have_message(I18n.t('flash.actions.destroy.success',
                                                       resource_name: Note.model_name.human))
        expect(response).to redirect_to(controller: 'notes')
      end

      it 'for a note belonging to someone else (delete as Instructor)' do
        @note = create(:note, creator_id: create(:ta).id)
        delete_as @instructor, :destroy, params: { course_id: course.id, id: @note.id }
        expect(assigns(:note)).not_to be_nil
        expect(flash[:success]).to have_message(I18n.t('flash.actions.destroy.success',
                                                       resource_name: Note.model_name.human))
        expect(response).to redirect_to(controller: 'notes')
      end

      it 'have noteable options for selection when viewing noteable_type Grouping' do
        noteable = create(:grouping)
        post_as @instructor, :create, params: { course_id: course.id,
                                                noteable_type: 'Grouping', note: { noteable_id: noteable.id } }
        expect(response).to have_http_status :success
      end

      it 'have noteable options for selection when viewing noteable_type Student' do
        noteable = create(:student)
        post_as @instructor, :create, params: { course_id: course.id,
                                                noteable_type: 'Student', note: { noteable_id: noteable.id } }
        expect(response).to have_http_status :success
      end

      it 'have noteable options for selection when viewing noteable_type Assignment' do
        noteable = create(:assignment)
        post_as @instructor, :create, params: { course_id: course.id,
                                                noteable_type: 'Assignment', note: { noteable_id: noteable.id } }
        expect(response).to have_http_status :success
      end
    end
  end
end
