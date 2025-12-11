describe Api::SectionsController do
  include AutomatedTestsHelper

  let(:section) { create(:section) }
  let(:instructor) { create(:instructor) }
  let(:course) { section.course }

  context 'An unauthorized attempt' do
    before do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
    end

    it 'fails to delete section' do
      delete :destroy, params: { course_id: course.id, id: section }
      expect(response).to have_http_status(:forbidden)
      expect(course.sections).to exist(section.id)
    end

    it 'fails to update section' do
      old_name = section.name
      put :update, params: { course_id: course.id, id: section.id, name: 'LEC999' }
      expect(response).to have_http_status(:forbidden)
      expect(section.name).to equal(old_name)
    end

    it 'fails to get sections index' do
      get :index, params: { course_id: course.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'fails to show section' do
      get :show, params: { course_id: course.id, id: section.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'An authorized attempt' do
    before do
      instructor.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{instructor.api_key.strip}"
    end

    context 'POST create' do
      it 'should create a new section when given the correct params' do
        post :create, params: { course_id: course.id, section: { name: 'LEC0301' } }
        expect(response).to have_http_status(:created)
        expect(course.sections.find_by(name: 'LEC0301').name).to eq('LEC0301')
      end

      it 'should throw a 422 error and not create a section with when given an invalid param' do
        post :create, params: { course_id: course.id, section: { name: '' } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(course.sections.find_by(name: '')).to be_nil
      end
    end

    context 'PUT update' do
      it 'successfully updates section' do
        put :update, params: { course_id: course.id, id: section.id, name: 'LEC345' }
        expect(response).to have_http_status(:ok)
        expect(course.sections.find_by(id: section.id).name).to eq('LEC345')
      end
    end

    context 'GET show' do
      context 'expecting an xml response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/xml'
          get :show, params: { course_id: course.id, id: section.id }
        end

        it 'should be successful' do
          expect(response).to have_http_status(:ok)
        end

        it 'should return info about the specific section' do
          expect(Hash.from_xml(response.body).dig('section', 'id')).to eq(section.id)
        end

        it 'should include all section attributes' do
          xml_keys = Hash.from_xml(response.body)['section'].keys.map(&:to_sym)
          model_attrs = Section.column_names.map(&:to_sym)
          expect(xml_keys).to match_array model_attrs
        end
      end

      context 'expecting an json response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/json'
          get :show, params: { course_id: course.id, id: section.id }
        end

        it 'should be successful' do
          expect(response).to have_http_status(:ok)
        end

        it 'should return info about the specific section' do
          expect(response.parsed_body['id']).to eq(section.id)
        end

        it 'should include all section attributes' do
          info = response.parsed_body
          json_keys = Set.new(info.keys.map(&:to_sym))
          model_attrs = Set.new(Section.column_names.map(&:to_sym))
          expect(json_keys).to eq Set.new(model_attrs)
        end
      end
    end

    context 'GET index' do
      context 'expecting an xml response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/xml'
          get :index, params: { course_id: course.id }
        end

        it 'should be successful' do
          expect(response).to have_http_status(:ok)
        end

        it 'should return info about all sections' do
          xml_ids = Hash.from_xml(response.body)['sections'].pluck('id')
          actual_ids = course.sections.map(&:id)
          expect(xml_ids).to eq(actual_ids)
        end

        it 'should include all attributes for each section' do
          xml_sections = Hash.from_xml(response.body)['sections']
          model_attrs = Section.column_names.map(&:to_sym)
          xml_sections.each do |section|
            xml_keys = section.keys.map(&:to_sym)
            expect(xml_keys).to match_array model_attrs
          end
        end
      end

      context 'expecting an json response' do
        before do
          request.env['HTTP_ACCEPT'] = 'application/json'
          get :index, params: { course_id: course.id }
        end

        it 'should be successful' do
          expect(response).to have_http_status(:ok)
        end

        it 'should return info about all sections' do
          json_ids = response.parsed_body.pluck('id')
          actual_ids = course.sections.map(&:id)
          expect(json_ids).to eq(actual_ids)
        end

        it 'should include all attributes for each section' do
          json_sections = response.parsed_body
          model_attrs = Section.column_names.map(&:to_sym)
          json_sections.each do |section|
            json_keys = section.keys.map(&:to_sym)
            expect(json_keys).to match_array model_attrs
          end
        end
      end
    end

    context 'DELETE destroy' do
      it 'successfully deletes section' do
        delete :destroy, params: { course_id: course.id, id: section }
        expect(response).to have_http_status(:ok)
        expect(course.sections).not_to exist(section.id)
      end

      it 'does not delete section because the section is non-empty (has students), with 403 code' do
        student = create(:student)
        section.students = [student]
        delete :destroy, params: { course_id: course.id, id: section }
        expect(response).to have_http_status(:conflict)
        expect(course.sections).to exist(section.id)
      end
    end
  end
end
