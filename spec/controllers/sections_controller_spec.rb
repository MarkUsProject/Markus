describe SectionsController do

  context 'A logged in Student' do
    before do
      @student = Student.create(user_name: 'jdoe',
                                last_name: 'doe',
                                first_name: 'john')
    end

    let(:section) { create :section }

    it 'on index' do
      get_as @student, :index
      expect(response).to have_http_status(403)
    end

    it 'on create new section' do
      post_as @student, :create
      expect(response).to have_http_status(403)
    end

    it 'on edit section' do
      post_as @student, :edit, params: { id: section.id }
      expect(response).to have_http_status(403)
    end

    it 'on update new section' do
      post_as @student, :update, params: { id: section.id }
      expect(response).to have_http_status(403)
    end

    it 'not be able to delete a section' do
      delete_as @student, :destroy, params: { id: section }
      expect(response).to have_http_status(403)
      expect(Section.find(section.id)).to be_truthy
    end
  end

  context 'A logged in Admin' do
    before do
      @admin = Admin.create(user_name: 'adoe',
                            last_name: 'doe',
                            first_name: 'adam')
    end

    let(:section) { create :section }
    let(:section2) { create :section }

    it 'on index' do
      get_as @admin, :index
      expect(response.status).to eq(200)
    end

    it 'on create new section' do
      post_as @admin, :create, params: { section: { name: 'section_01' } }

      expect(response).to be_redirect
      i18t_string = [I18n.t('sections.create.success', name: 'section_01')].map { |f| extract_text f }
      expect(flash[:success].map { |f| extract_text f }).to eq(i18t_string)
      expect(Section.find_by_name('section_01')).to be_truthy
    end

    it 'not be able to create a section with the same name as a existing one' do
      post_as @admin, :create, params: { section: { name: section.name } }
      expect(response.status).to eq(200)
      expect(flash[:error].map { |f| extract_text f }).to eq([I18n.t('sections.create.error')].map { |f| extract_text f })
    end

    it 'not be able to create a section with a blank name' do
      post_as @admin, :create, params: { section: { name: '' } }
      expect(Section.find_by_name('')).to be_nil
      expect(response.status).to eq(200)
      expect(flash[:error].map { |f| extract_text f }).to eq([I18n.t('sections.create.error')].map { |f| extract_text f })
    end

    it 'on edit section' do
      post_as @admin, :edit, params: { id: section.id }
      expect(response.status).to eq(200)
    end

    it 'be able to update a section name to "no section"' do
      put_as @admin, :update, params: { id: section.id, section: { name: 'no section' } }

      expect(response).to be_redirect
      i18t_string = [I18n.t('sections.update.success', name: 'no section')].map { |f| extract_text f }
      expect(flash[:success].map { |f| extract_text f }).to eq(i18t_string)
      expect(Section.find_by_name('no section')).to be_truthy
    end

    it 'not see a table if no students in this section' do
      get_as @admin, :edit, params: { id: section.id }
      expect(response.body.to_s.match('section_students')).to be_nil
    end

    it 'not be able to edit a section name to an existing name' do
      put_as @admin, :update, params: { id: section.id, section: { name: section2.name } }
      expect(response.status).to eq(200)
      expect(flash[:error].map { |f| extract_text f }).to eq([I18n.t('sections.update.error')].map { |f| extract_text f })
    end

    context 'with an already created section' do
      it 'be able to delete a section' do
        delete_as @admin, :destroy, params: { id: section.id }
        i18t_string = [I18n.t('sections.destroy.success')].map { |f| extract_text f }
        expect(flash[:success].map { |f| extract_text f }).to eq(i18t_string)
      end

      it 'not be able to delete a section with students in it' do
        student = Student.create(user_name: 'jdoe',
                                  last_name: 'doe',
                                  first_name: 'john')
        section.students << student
        delete_as @admin, :destroy, params: { id: section.id }
        i18t_string = [I18n.t('sections.destroy.not_empty')].map { |f| extract_text f }
        expect(flash[:error].map { |f| extract_text f }).to eq(i18t_string)
        expect(Section.find(section.id)).to be_truthy
      end
    end
  end
end
