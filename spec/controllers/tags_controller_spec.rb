describe TagsController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  let(:assignment) { FactoryBot.create(:assignment) }

  describe '#index' do
    it 'returns correct JSON data' do
      tag = create(:tag)
      get :index, params: { assignment_id: assignment.id, format: :json }
      expected = [{
        'id' => tag.id,
        'name' => tag.name,
        'description' => tag.description,
        'creator' => "#{tag.user.first_name} #{tag.user.last_name}",
        'use' => tag.groupings.size
      }]
      expect(response.parsed_body).to eq expected
    end
  end

  describe '#create' do
    let(:grouping) { create(:grouping, assignment: assignment) }

    it 'creates a new tag' do
      post :create, params: { tag: { name: 'tag', description: 'tag description' },
                              assignment_id: assignment.id }
      expect(Tag.find_by(name: 'tag', description: 'tag description')).to_not be_nil
    end

    it 'associates the new tag with a grouping when passed grouping_id' do
      post :create, params: { tag: { name: 'tag', description: 'tag description' },
                              grouping_id: grouping.id, assignment_id: assignment.id }
      tags = grouping.tags
      expect(tags.size).to eq 1
      expect(tags.first.name).to eq 'tag'
      expect(tags.first.description).to eq 'tag description'
    end
  end

  describe '#update' do
    let(:tag) { create(:tag, name: 'tag', description: 'description') }

    it 'updates tag name and description' do
      post :update, params: { id: tag.id, tag: { name: 'new name', description: 'new description' },
                              assignment_id: assignment.id }
      tag.reload
      expect(tag.name).to eq 'new name'
      expect(tag.description).to eq 'new description'
    end
  end

  describe '#destroy' do
    it 'destroys an existing tag' do
      tag = create(:tag)
      delete :destroy, params: { id: tag.id, assignment_id: assignment.id }
      expect(Tag.count).to eq 0
    end
  end

  describe '#upload' do
    include_examples 'a controller supporting upload' do
      let(:params) { { assignment_id: assignment.id } }
    end

    before :each do
      create(:admin, user_name: 'a')
      # We need to mock the rack file to return its content when
      # the '.read' method is called to simulate the behaviour of
      # the http uploaded file
      @file_good_csv = fixture_file_upload(
        'files/tags/form_good.csv', 'text/csv'
      )
      allow(@file_good_csv).to receive(:read).and_return(
        File.read(fixture_file_upload(
                    'files/tags/form_good.csv',
                    'text/csv'
                  ))
      )

      @file_good_yml = fixture_file_upload(
        'files/tags/form_good.yml', 'text/yaml'
      )
      allow(@file_good_yml).to receive(:read).and_return(
        File.read(fixture_file_upload('files/tags/form_good.yml', 'text/yaml'))
      )

      @file_invalid_column = fixture_file_upload(
        'files/tags/form_invalid_column.csv', 'text/csv'
      )
      allow(@file_invalid_column).to receive(:read).and_return(
        File.read(fixture_file_upload(
                    'files/tags/form_invalid_column.csv',
                    'text/csv'
                  ))
      )
    end

    it 'accepts a valid CSV file' do
      post :upload, params: { upload_file: @file_good_csv, assignment_id: assignment.id }

      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(flash[:success].map { |f| extract_text f }).to eq([I18n.t('upload_success',
                                                                       count: 2)].map { |f| extract_text f })
      expect(response).to redirect_to action: :index

      expect(Tag.find_by(name: 'tag').description).to eq('desc')
      expect(Tag.find_by(name: 'tag1').description).to eq('desc1')
    end

    it 'accepts a valid YML file' do
      post :upload, params: { upload_file: @file_good_yml, assignment_id: assignment.id }

      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to action: :index

      expect(Tag.find_by(name: 'tag').description).to eq('desc')
      expect(Tag.find_by(name: 'tag1').description).to eq('desc1')
    end

    it 'does not accept files with invalid columns' do
      post :upload, params: { upload_file: @file_invalid_column, assignment_id: assignment.id }

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to action: :index
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

      before :each do
        @user = create(:student)
        @tag1 = Tag.find_or_create_by(name: 'tag1')
        @tag1.name = 'tag1'
        @tag1.description = 'tag1_description'
        @tag1.user = @user
        @tag1.save

        @tag2 = Tag.find_or_create_by(name: 'tag2')
        @tag2.name = 'tag2'
        @tag2.description = 'tag2_description'
        @tag2.user = @user
        @tag2.save
      end

      it 'responds with appropriate status' do
        get :download, params: { assignment_id: assignment.id }, format: 'csv'
        expect(response.status).to eq(200)
      end

      # parse header object to check for the right disposition
      it 'sets disposition as attachment' do
        get :download, params: { assignment_id: assignment.id }, format: 'csv'
        d = response.header['Content-Disposition'].split.first
        expect(d).to eq 'attachment;'
      end

      it 'expects a call to send_data' do
        csv_data =
          "#{@tag1.name},#{@tag1.description},#{@user.user_name}\n" \
            "#{@tag2.name},#{@tag2.description},#{@user.user_name}\n"
        expect(@controller).to receive(:send_data).with(csv_data, csv_options) {
          # to prevent a 'missing template' error
          @controller.head :ok
        }
        get :download, params: { assignment_id: assignment.id }, format: 'csv'
      end

      # parse header object to check for the right content type
      it 'returns text/csv type' do
        get :download, params: { assignment_id: assignment.id }, format: 'csv'
        expect(response.media_type).to eq 'text/csv'
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

      before :each do
        @user = create(:student)
        @tag1 = Tag.find_or_create_by(name: 'tag1')
        @tag1.name = 'tag1'
        @tag1.description = 'tag1_description'
        @tag1.user = @user
        @tag1.save

        @tag2 = Tag.find_or_create_by(name: 'tag2')
        @tag2.name = 'tag2'
        @tag2.description = 'tag2_description'
        @tag2.user = @user
        @tag2.save
      end

      it 'responds with appropriate status' do
        get :download, params: { assignment_id: assignment.id }, format: 'yml'
        expect(response.status).to eq(200)
      end

      # parse header object to check for the right disposition
      it 'sets disposition as attachment' do
        get :download, params: { assignment_id: assignment.id }, format: 'yml'
        d = response.header['Content-Disposition'].split.first
        expect(d).to eq 'attachment;'
      end

      it 'expects a call to send_data' do
        yml_data = [
          {
            name: @tag1.name,
            description: @tag1.description,
            user: @user.user_name
          },
          {
            name: @tag2.name,
            description: @tag2.description,
            user: @user.user_name
          }
        ].to_yaml
        expect(@controller).to receive(:send_data).with(yml_data, yml_options) {
          # to prevent a 'missing template' error
          @controller.head :ok
        }
        get :download, params: { assignment_id: assignment.id }, format: 'yml'
      end

      # parse header object to check for the right content type
      it 'returns text/yml type' do
        get :download, params: { assignment_id: assignment.id }, format: 'yml'
        expect(response.media_type).to eq 'text/yml'
      end
    end
  end
end
