describe Api::SubmissionFilesController do
  context 'An unauthenticated request' do
    before :each do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it 'should fail to authenticate a GET index request' do
      get :index, params: { assignment_id: 1, group_id: 1 }
      expect(response.status).to eq(403)
    end

    it 'should fail to authenticate a GET show request' do
      get :show, params: { id: 1, assignment_id: 1, group_id: 1 }
      expect(response.status).to eq(403)
    end

    it 'should fail to authenticate a POST create request' do
      post :create, params: { assignment_id: 1, group_id: 1 }

      expect(response.status).to eq(403)
    end

    it 'should fail to authenticate a PUT update request' do
      put :create, params: { id: 1, assignment_id: 1, group_id: 1 }
      expect(response.status).to eq(403)
    end

    it 'should fail to authenticate a DELETE destroy request' do
      delete :destroy, params: { id: 1, assignment_id: 1, group_id: 1 }
      expect(response.status).to eq(403)
    end
  end
  context 'An authenticated request' do
    let(:assignment) { create :assignment }
    let(:grouping) { create :grouping_with_inviter, assignment: assignment }
    let(:group) { grouping.group }
    let(:file_content) { Array.new(2) { Faker::TvShows::HeyArnold.quote } }
    let(:file_names) { Array.new(2) { Faker::File.file_name(dir: '') } }
    before :each do
      admin = create :admin
      admin.reset_api_key
      request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{admin.api_key.strip}"
      group.access_repo do |repo|
        txn = repo.get_transaction(grouping.inviter.user_name)
        file_content.each_with_index do |content, i|
          filepath = File.join(assignment.repository_folder, file_names[i])
          txn.add(filepath, content)
        end
        repo.commit(txn)
        Submission.generate_new_submission(grouping, repo.get_latest_revision)
      end
    end
    context 'GET index' do
      let(:aid) { assignment.id }
      let(:gid) { group.id }
      let(:file_name) { nil }
      before :each do
        get :index, params: { assignment_id: aid, group_id: gid, filename: file_name }
      end
      context 'when no specific file is selected' do
        it 'should be successful' do
          expect(response.status).to eq(200)
        end
        it 'should return a zip containing both files' do
          files = 0
          Zip::InputStream.open(StringIO.new(response.body)) do |io|
            while (entry = io.get_next_entry)
              files += 1 unless entry.name_is_directory?
            end
          end
          expect(files).to eq 2
        end
        it 'should return a zip with the content of both files' do
          content = []
          Zip::InputStream.open(StringIO.new(response.body)) do |io|
            while (entry = io.get_next_entry)
              content << io.read.strip.force_encoding('utf-8') unless entry.name_is_directory?
            end
          end
          expect(content).to contain_exactly(*file_content)
        end
      end
      context 'when a specific file is selected' do
        let(:file_name) { File.basename(file_names[0]) }
        it 'should be successful' do
          expect(response.status).to eq(200)
        end
        it 'should return a non-zipped  containing the content of a single file' do
          expect(response.body).to eq(file_content[0])
        end
      end
      context 'when a non-existant file is selected' do
        let(:file_name) { file_names.map { |f| File.basename f }.join }
        it 'should return a 422 error' do
          expect(response.status).to eq(422)
        end
      end
      context 'when an assignment does not exist' do
        let(:aid) { assignment.id + 1 }
        it 'should return a 404 error' do
          expect(response.status).to eq(404)
        end
      end
      context 'when a group does not exist' do
        let(:gid) { group.id + 1 }
        it 'should return a 404 error' do
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
