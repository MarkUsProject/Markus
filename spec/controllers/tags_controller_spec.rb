describe TagsController do
  # TODO: add 'role is from a different course' shared tests to each route test below

  let(:assignment) { create(:assignment) }
  let(:instructor) { create(:instructor) }
  let(:course) { instructor.course }

  describe '#index' do
    let!(:tag) { create(:tag) }
    let!(:assignment_tag) { create(:tag, assessment: assignment) }
    let(:tags) { [tag, assignment_tag] }

    context 'only getting the tags for the specified assignment' do
      it 'returns correct JSON data' do
        get_as instructor, :index, params: { course_id: course.id, assignment_id: assignment.id, format: :json }
        expected = [{ id: assignment_tag.id, name: assignment_tag.name, description: assignment_tag.description,
                      creator: "#{assignment_tag.role.first_name} #{assignment_tag.role.last_name}",
                      use: assignment_tag.groupings.size }.stringify_keys]
        expect(response.parsed_body).to match_array(expected)
      end
    end

    context 'getting tags for all assignments' do
      it 'returns correct JSON data' do
        get_as instructor, :index, params: { course_id: course.id, format: :json }
        expected = tags.map do |t|
          { id: t.id, name: t.name, description: t.description,
            creator: "#{t.role.first_name} #{t.role.last_name}", use: t.groupings.size }.stringify_keys
        end

        expect(response.parsed_body).to match_array(expected)
      end
    end
  end

  describe '#create' do
    let(:grouping) { create(:grouping, assignment: assignment) }

    it 'creates a new tag' do
      post_as instructor, :create, params: { tag: { name: 'tag', description: 'tag description' },
                                             assignment_id: assignment.id, course_id: course.id }
      expect(Tag.find_by(name: 'tag', description: 'tag description')).not_to be_nil
    end

    it 'does not create an invalid tag' do
      post_as instructor, :create, params: { tag: { name: '', description: 'tag description' },
                                             assignment_id: assignment.id, course_id: course.id }
      expect(Tag.find_by(name: '', description: 'tag description')).to be_nil
      expect(flash[:error]).to have_message(I18n.t('flash.actions.create.error', resource_name: Tag.model_name.human))
    end

    it 'associates the new tag with a grouping when passed grouping_id' do
      post_as instructor, :create, params: { tag: { name: 'tag', description: 'tag description' },
                                             grouping_id: grouping.id, course_id: course.id }
      tags = grouping.tags
      expect(tags.size).to eq 1
      expect(tags.first.name).to eq 'tag'
      expect(tags.first.description).to eq 'tag description'
    end

    it 'associates the new tag with an assessment' do
      post_as instructor, :create, params: { tag: { name: 'tag', description: 'tag description' },
                                             assignment_id: assignment.id, course_id: course.id }
      expect(Tag.find_by(name: 'tag', description: 'tag description').assessment.id).to eq assignment.id
    end
  end

  describe '#update' do
    let(:tag) { create(:tag, name: 'tag', description: 'description') }

    it 'updates tag name and description' do
      post_as instructor, :update, params: { id: tag.id, tag: { name: 'new name', description: 'new description' },
                                             course_id: course.id }
      tag.reload
      expect(tag.name).to eq 'new name'
      expect(tag.description).to eq 'new description'
    end
  end

  describe '#destroy' do
    it 'destroys an existing tag' do
      tag = create(:tag)
      delete_as instructor, :destroy, params: { id: tag.id, course_id: course.id }
      expect(Tag.count).to eq 0
    end
  end

  describe '#upload' do
    it_behaves_like 'a controller supporting upload' do
      let(:params) { { course_id: course.id } }
    end

    before do
      create(:instructor, user: create(:end_user, user_name: 'a'))

      @file_good_csv = fixture_file_upload('tags/form_good.csv', 'text/csv')
      @file_good_yml = fixture_file_upload('tags/form_good.yml', 'text/yaml')
      @file_invalid_column = fixture_file_upload('tags/form_invalid_column.csv', 'text/csv')
    end

    it 'accepts a valid CSV file' do
      post_as instructor, :upload,
              params: { upload_file: @file_good_csv, assignment_id: assignment.id, course_id: course.id }

      expect(response).to have_http_status(:found)
      expect(flash[:error]).to be_nil
      expect(flash[:success]).to have_message(I18n.t('upload_success', count: 2))
      expect(response).to redirect_to course_tags_path(course, assignment_id: assignment.id)

      expect(Tag.find_by(name: 'tag').description).to eq('desc')
      expect(Tag.find_by(name: 'tag1').description).to eq('desc1')
    end

    it 'accepts a valid YML file' do
      post_as instructor, :upload,
              params: { upload_file: @file_good_yml, assignment_id: assignment.id, course_id: course.id }

      expect(response).to have_http_status(:found)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to course_tags_path(course, assignment_id: assignment.id)

      expect(Tag.find_by(name: 'tag').description).to eq('desc')
      expect(Tag.find_by(name: 'tag1').description).to eq('desc1')
    end

    it 'does not accept files with invalid columns' do
      post_as instructor, :upload,
              params: { upload_file: @file_invalid_column, assignment_id: assignment.id, course_id: course.id }

      expect(response).to have_http_status(:found)
      expect(flash[:error]).not_to be_empty
      expect(response).to redirect_to course_tags_path(course, assignment_id: assignment.id)
    end
  end

  describe '#download' do
    context 'when given format: csv' do
      let(:csv_options) do
        {
          type: 'text/csv',
          disposition: 'attachment',
          filename: 'tag_list.csv'
        }
      end

      before do
        @role = create(:student)
        @tag1 = Tag.find_or_create_by(name: 'tag1')
        @tag1.name = 'tag1'
        @tag1.description = 'tag1_description'
        @tag1.role = @role
        @tag1.save

        @tag2 = Tag.find_or_create_by(name: 'tag2', assessment: assignment)
        @tag2.name = 'tag2'
        @tag2.description = 'tag2_description'
        @tag2.role = @role
        @tag2.save
      end

      shared_examples 'upload csv' do
        it 'responds with appropriate status' do
          get_as instructor, :download, params: params, format: 'csv'
          expect(response).to have_http_status(:ok)
        end

        # parse header object to check for the right disposition
        it 'sets disposition as attachment' do
          get_as instructor, :download, params: params, format: 'csv'
          d = response.header['Content-Disposition'].split.first
          expect(d).to eq 'attachment;'
        end

        it 'expects a call to send_data' do
          if params[:assignment_id]
            csv_data = "#{@tag2.name},#{@tag2.description},#{@role.user_name}\n"
          else
            csv_data = "#{@tag1.name},#{@tag1.description},#{@role.user_name}\n" \
                       "#{@tag2.name},#{@tag2.description},#{@role.user_name}\n"
          end
          expect(@controller).to receive(:send_data).with(csv_data, csv_options) {
            # to prevent a 'missing template' error
            @controller.head :ok
          }
          get_as instructor, :download, params: params, format: 'csv'
        end

        # parse header object to check for the right content type
        it 'returns text/csv type' do
          get_as instructor, :download, params: params, format: 'csv'
          expect(response.media_type).to eq 'text/csv'
        end
      end

      context 'only for an assignment' do
        let(:params) { { course_id: course.id, assignment_id: assignment.id } }

        it_behaves_like 'upload csv'
      end

      context 'for all assignments' do
        let(:params) { { course_id: course.id } }

        it_behaves_like 'upload csv'
      end
    end

    context 'when given format: yml' do
      let(:yml_options) do
        {
          type: 'text/yml',
          disposition: 'attachment',
          filename: 'tag_list.yml'
        }
      end

      before do
        @role = create(:student)
        @tag1 = Tag.find_or_create_by(name: 'tag1')
        @tag1.name = 'tag1'
        @tag1.description = 'tag1_description'
        @tag1.role = @role
        @tag1.save

        @tag2 = Tag.find_or_create_by(name: 'tag2', assessment: assignment)
        @tag2.name = 'tag2'
        @tag2.description = 'tag2_description'
        @tag2.role = @role
        @tag2.save
      end

      shared_examples 'upload yml' do
        it 'responds with appropriate status' do
          get_as instructor, :download, params: params, format: 'yml'
          expect(response).to have_http_status(:ok)
        end

        # parse header object to check for the right disposition
        it 'sets disposition as attachment' do
          get_as instructor, :download, params: params, format: 'yml'
          d = response.header['Content-Disposition'].split.first
          expect(d).to eq 'attachment;'
        end

        it 'expects a call to send_data' do
          if params[:assignment_id]
            yml_data = [{ name: @tag2.name, description: @tag2.description, user: @role.user_name }]
          else
            yml_data = [
              {
                name: @tag1.name,
                description: @tag1.description,
                user: @role.user_name
              },
              {
                name: @tag2.name,
                description: @tag2.description,
                user: @role.user_name
              }
            ]
          end
          expect(@controller).to receive(:send_data).with(yml_data.to_yaml, yml_options) {
            # to prevent a 'missing template' error
            @controller.head :ok
          }
          get_as instructor, :download, params: params, format: 'yml'
        end

        # parse header object to check for the right content type
        it 'returns text/yml type' do
          get_as instructor, :download, params: params, format: 'yml'
          expect(response.media_type).to eq 'text/yml'
        end
      end

      context 'only for an assignment' do
        let(:params) { { course_id: course.id, assignment_id: assignment.id } }

        it_behaves_like 'upload yml'
      end

      context 'for all assignments' do
        let(:params) { { course_id: course.id } }

        it_behaves_like 'upload yml'
      end
    end
  end
end
