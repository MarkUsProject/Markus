describe SectionsController do
  context 'A logged in Student' do
    before do
      @student = create(:student)
    end

    let(:section) { create(:section) }
    let(:course) { section.course }

    it 'on index' do
      get_as @student, :index, params: { course_id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'on create new section' do
      post_as @student, :create, params: { course_id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'on edit section' do
      post_as @student, :edit, params: { course_id: course.id, id: section.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'on update new section' do
      post_as @student, :update, params: { course_id: course.id, id: section.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'not be able to delete a section' do
      delete_as @student, :destroy, params: { course_id: course.id, id: section }
      expect(response).to have_http_status(:forbidden)
      expect(Section.find(section.id)).to be_truthy
    end
  end

  context 'A logged in Instructor' do
    before do
      @instructor = create(:instructor)
    end

    let(:section) { create(:section) }
    let(:section2) { create(:section) }
    let(:course) { section.course }

    it 'on index' do
      get_as @instructor, :index, params: { course_id: course.id }
      expect(response).to have_http_status(:ok)
    end

    it 'on create new section' do
      post_as @instructor, :create, params: { course_id: course.id, section: { name: 'section_01' } }

      expect(response).to be_redirect
      expect(flash[:success]).to have_message(I18n.t('sections.create.success', name: 'section_01'))
      expect(Section.find_by(name: 'section_01')).to be_truthy
    end

    it 'not be able to create a section with the same name as a existing one' do
      post_as @instructor, :create, params: { course_id: course.id, section: { name: section.name } }
      expect(response).to have_http_status(:ok)
      expect(flash[:error]).to have_message(I18n.t('sections.create.error'))
    end

    it 'not be able to create a section with a blank name' do
      post_as @instructor, :create, params: { course_id: course.id, section: { name: '' } }
      expect(Section.find_by(name: '')).to be_nil
      expect(response).to have_http_status(:ok)
      expect(flash[:error]).to have_message(I18n.t('sections.create.error'))
    end

    it 'on edit section' do
      post_as @instructor, :edit, params: { course_id: course.id, id: section.id }
      expect(response).to have_http_status(:ok)
    end

    it 'be able to update a section name to "no section"' do
      put_as @instructor, :update, params: { course_id: course.id, id: section.id, section: { name: 'no section' } }

      expect(response).to be_redirect
      expect(flash[:success]).to have_message(I18n.t('sections.update.success', name: 'no section'))
      expect(Section.find_by(name: 'no section')).to be_truthy
    end

    it 'not see a table if no students in this section' do
      get_as @instructor, :edit, params: { course_id: course.id, id: section.id }
      expect(response.body.to_s.match('section_students')).to be_nil
    end

    it 'not be able to edit a section name to an existing name' do
      put_as @instructor, :update, params: { course_id: course.id, id: section.id, section: { name: section2.name } }
      expect(response).to have_http_status(:ok)
      expect(flash[:error]).to have_message(I18n.t('sections.update.error'))
    end

    context 'with an already created section' do
      it 'be able to delete a section' do
        delete_as @instructor, :destroy, params: { course_id: course.id, id: section.id }
        expect(flash[:success]).to have_message(I18n.t('sections.destroy.success'))
      end

      it 'not be able to delete a section with students in it' do
        student = create(:student)
        section.students << student
        delete_as @instructor, :destroy, params: { course_id: course.id, id: section.id }
        expect(flash[:error]).to have_message(I18n.t('sections.destroy.not_empty'))
        expect(Section.find(section.id)).to be_truthy
      end
    end
  end
end
