describe Api::StarterFileGroupsController do
  let(:admin) { create :admin }
  let(:assignment) { create :assignment }
  let(:http_accept) { 'application/xml' }

  before :each do
    admin.reset_api_key
    request.env['HTTP_AUTHORIZATION'] = "MarkUsAuth #{admin.api_key.strip}"
    request.env['HTTP_ACCEPT'] = http_accept
  end

  shared_examples 'unauthenticated request' do
    it 'should fail to authenticate' do
      request.env['HTTP_AUTHORIZATION'] = 'garbage http_header'
      subject
      expect(response.status).to eq(403)
    end
  end

  describe '#create' do
    subject { post :create, params: params }
    let(:params) do
      { assignment_id: assignment.id, name: 'b', entry_rename: 'b', use_rename: true }
    end
    include_examples 'unauthenticated request'

    it 'should create a new starter file group' do
      subject
      expect(assignment.reload.starter_file_groups).not_to be_empty
    end
    it 'should update the name' do
      subject
      expect(assignment.reload.starter_file_groups.first.name).to eq 'b'
    end
    it 'should update the entry_rename' do
      subject
      expect(assignment.reload.starter_file_groups.first.entry_rename).to eq 'b'
    end
    it 'should update the use_rename' do
      subject
      expect(assignment.reload.starter_file_groups.first.use_rename).to eq true
    end
    context 'should set a default name if not given' do
      before { params.delete(:name) }
      it 'should set a default name' do
        subject
        expect(assignment.reload.starter_file_groups.first.name).not_to be_blank
      end
    end
  end
  describe '#update' do
    subject { post :update, params: params }
    let(:starter_file_group) { build :starter_file_group }
    let(:params) { { assignment_id: assignment.id, id: starter_file_group.id || -1 } }
    include_examples 'unauthenticated request'

    context 'when the starter code group exists' do
      context 'for the given assignment' do
        let(:starter_file_group) do
          create :starter_file_group, assignment: assignment, name: 'a', entry_rename: 'a', use_rename: false
        end
        let(:params) do
          { assignment_id: assignment.id, id: starter_file_group.id, name: 'b', entry_rename: 'b', use_rename: true }
        end
        it 'should update the name' do
          subject
          expect(starter_file_group.reload.name).to eq 'b'
        end
        it 'should update the entry_rename' do
          subject
          expect(starter_file_group.reload.entry_rename).to eq 'b'
        end
        it 'should update the use_rename' do
          subject
          expect(starter_file_group.reload.use_rename).to eq true
        end
        context 'when the starter file type is shuffle' do
          let(:grouping) { create :grouping, assignment: assignment }
          before { assignment.assignment_params.update!(starter_file_type: 'shuffle') }
        end
      end
      context 'for a different assignment' do
        let(:starter_file_group) { create :starter_file_group }
        it 'should return a 404 error' do
          subject
          expect(response.status).to eq(404)
        end
      end
    end
    context 'when the starter code does not exist' do
      it 'should return a 404 error' do
        subject
        expect(response.status).to eq(404)
      end
    end
  end
  describe '#destroy' do
    subject { delete :destroy, params: { assignment_id: assignment.id, id: starter_file_group.id || -1 } }
    let(:starter_file_group) { build :starter_file_group }
    include_examples 'unauthenticated request'

    context 'when the starter file gorup exists' do
      context 'for this assignment' do
        let(:starter_file_group) { create :starter_file_group, assignment: assignment }
        it 'should delete the starter file group' do
          subject
          expect { starter_file_group.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
      context 'for a different assignment' do
        let(:starter_file_group) { create :starter_file_group }
        it 'should return a 404 error' do
          subject
          expect(response.status).to eq(404)
        end
        it 'should not delete the starter file group' do
          subject
          expect(starter_file_group.reload).to eq starter_file_group
        end
      end
    end
    context 'when the starter code does not exist' do
      it 'should return a 404 error' do
        subject
        expect(response.status).to eq(404)
      end
    end
  end
  describe '#index' do
    subject { get :index, params: { assignment_id: assignment.id } }
    include_examples 'unauthenticated request'
    context 'when there are starter file groups for this assignment' do
      let!(:starter_file_groups) { create_list :starter_file_group, 3, assignment: assignment }
      let(:data) do
        assignment.starter_file_groups
                  .pluck_to_hash(:id, :assessment_id, :entry_rename, :use_rename, :name)
      end
      before { subject }
      context 'expecting xml' do
        it 'should contain the correct data' do
          stringed_data = data.map { |h| h.transform_values(&:to_s) }
          expect(Hash.from_xml(response.body)['starter_file_groups']['starter_file_group']).to eq stringed_data
        end
      end
      context 'expecting json' do
        let(:http_accept) { 'application/json' }
        it 'should contain the correct data' do
          expect(JSON.parse(response.body)).to eq data
        end
      end
    end
    context 'when there are starter file groups for another assignment' do
      let!(:starter_file_groups) { create_list :starter_file_group, 3 }
      before { subject }
      context 'expecting xml' do
        it 'should return empty data' do
          expect(Hash.from_xml(response.body['starter_file_groups'])).to be_nil
        end
      end
      context 'expecting json' do
        let(:http_accept) { 'application/json' }
        it 'should return empty data' do
          expect(JSON.parse(response.body)).to eq []
        end
      end
    end
  end
  describe '#show' do
    subject { get :show, params: { assignment_id: assignment.id, id: starter_file_group.id || 1 } }
    let(:starter_file_group) { build :starter_file_group }
    include_examples 'unauthenticated request'
    context 'when there are starter file groups for this assignment' do
      let(:starter_file_group) { create :starter_file_group, assignment: assignment }
      let(:data) do
        assignment.starter_file_groups
                  .pluck_to_hash(:id, :assessment_id, :entry_rename, :use_rename, :name)
                  .first
      end
      before { subject }
      context 'expecting xml' do
        it 'should contain the correct data' do
          stringed_data = data.transform_values(&:to_s)
          expect(Hash.from_xml(response.body)['starter_file_group']).to eq stringed_data
        end
      end
      context 'expecting json' do
        let(:http_accept) { 'application/json' }
        it 'should contain the correct data' do
          expect(JSON.parse(response.body)).to eq data
        end
      end
    end
    context 'when there are starter file groups for another assignment' do
      let(:starter_file_group) { create :starter_file_group }
      before { subject }
      context 'expecting xml' do
        it 'should return empty data' do
          expect(Hash.from_xml(response.body['starter_file_group'])).to be_nil
        end
      end
      context 'expecting json' do
        let(:http_accept) { 'application/json' }
        xit 'should return empty data' do # this fails on travis only
          expect(response.body).to be_empty
        end
      end
    end
  end

  shared_examples 'updates starter_file_changed' do
    let(:grouping1) { create :grouping, assignment: assignment }
    let(:grouping2) { create :grouping, assignment: assignment }
    before do
      grouping1
      starter_file_group
      grouping2
    end
    it 'should set starter_file_changed for the related grouping' do
      expect { subject }.to(change { grouping2.reload.starter_file_changed })
    end
    it 'should not set starter_file_changed for the unrelated grouping' do
      expect { subject }.not_to(change { grouping1.reload.starter_file_changed })
    end
  end

  describe '#create_file' do
    subject do
      post :create_file, params: { filename: 'a',
                                   file_content: 'a',
                                   assignment_id: assignment.id,
                                   id: starter_file_group.id || -1 }
    end
    let(:starter_file_group) { build :starter_file_group }
    include_examples 'unauthenticated request'
    context 'when the starter file exists' do
      context 'for this assignment' do
        let(:starter_file_group) { create :starter_file_group_with_entries, assignment: assignment }
        it 'should add a file to the group' do
          subject
          expect(starter_file_group.files_and_dirs).to include 'a'
        end
        it 'should create a starter file entry' do
          subject
          expect(starter_file_group.starter_file_entries.pluck(:path)).to include 'a'
        end
        include_examples 'updates starter_file_changed'
      end
      context 'for a different assignment' do
        let(:starter_file_group) { create :starter_file_group }
        it 'should return a 404 error' do
          subject
          expect(response.status).to eq(404)
        end
      end
    end
    context 'when the starter code does not exist' do
      it 'should return a 404 error' do
        subject
        expect(response.status).to eq(404)
      end
    end
  end
  describe '#create_folder' do
    subject do
      post :create_folder, params: { folder_path: 'a', assignment_id: assignment.id, id: starter_file_group.id || -1 }
    end
    let(:starter_file_group) { build :starter_file_group }
    include_examples 'unauthenticated request'
    context 'when the starter file exists' do
      context 'for this assignment' do
        let(:starter_file_group) { create :starter_file_group_with_entries, assignment: assignment }
        it 'should add a folder to the group' do
          subject
          expect(starter_file_group.files_and_dirs).to include 'a'
        end
        it 'should create a starter file entry' do
          subject
          expect(starter_file_group.starter_file_entries.pluck(:path)).to include 'a'
        end
        include_examples 'updates starter_file_changed'
      end
      context 'for a different assignment' do
        let(:starter_file_group) { create :starter_file_group }
        it 'should return a 404 error' do
          subject
          expect(response.status).to eq(404)
        end
      end
    end
    context 'when the starter code does not exist' do
      it 'should return a 404 error' do
        subject
        expect(response.status).to eq(404)
      end
    end
  end
  describe '#remove_file' do
    subject do
      delete :remove_file, params: { filename: 'q2.txt', assignment_id: assignment.id, id: starter_file_group.id || -1 }
    end
    let(:starter_file_group) { build :starter_file_group }
    include_examples 'unauthenticated request'
    context 'when the starter file exists' do
      context 'for this assignment' do
        let(:starter_file_group) { create :starter_file_group_with_entries, assignment: assignment }
        it 'should remove a file from the group' do
          subject
          expect(starter_file_group.files_and_dirs).not_to include 'q2.txt'
        end
        it 'should remove a starter file entry' do
          subject
          expect(starter_file_group.starter_file_entries.pluck(:path)).not_to include 'q2.txt'
        end
        include_examples 'updates starter_file_changed'
      end
      context 'for a different assignment' do
        let(:starter_file_group) { create :starter_file_group }
        it 'should return a 404 error' do
          subject
          expect(response.status).to eq(404)
        end
      end
    end
    context 'when the starter code does not exist' do
      it 'should return a 404 error' do
        subject
        expect(response.status).to eq(404)
      end
    end
  end
  describe '#remove_folder' do
    subject do
      delete :remove_folder, params: { folder_path: 'q1',
                                       assignment_id: assignment.id,
                                       id: starter_file_group.id || -1 }
    end
    let(:starter_file_group) { build :starter_file_group }
    include_examples 'unauthenticated request'
    context 'when the starter file exists' do
      context 'for this assignment' do
        let(:starter_file_group) { create :starter_file_group_with_entries, assignment: assignment }
        it 'should remove a folder and all its descendants from the group' do
          subject
          expect(starter_file_group.files_and_dirs).not_to include 'q1'
          expect(starter_file_group.files_and_dirs).not_to include 'q1/q1.txt'
        end
        it 'should remove a starter file entry' do
          subject
          expect(starter_file_group.starter_file_entries.pluck(:path)).not_to include 'q1'
        end
        include_examples 'updates starter_file_changed'
      end
      context 'for a different assignment' do
        let(:starter_file_group) { create :starter_file_group }
        it 'should return a 404 error' do
          subject
          expect(response.status).to eq(404)
        end
      end
    end
    context 'when the starter code does not exist' do
      it 'should return a 404 error' do
        subject
        expect(response.status).to eq(404)
      end
    end
  end
  describe '#entries' do
    subject { get :entries, params: { assignment_id: assignment.id, id: starter_file_group.id || -1 } }
    let(:starter_file_group) { build :starter_file_group }
    include_examples 'unauthenticated request'
    context 'when the starter file exists' do
      context 'for this assignment' do
        let(:starter_file_group) { create :starter_file_group_with_entries, assignment: assignment }
        before { subject }
        context 'expecting xml' do
          it 'should contain the correct data' do
            expect(Hash.from_xml(response.body)['paths']['path']).to contain_exactly('q1', 'q1/q1.txt', 'q2.txt')
          end
        end
        context 'expecting json' do
          let(:http_accept) { 'application/json' }
          it 'should contain the correct data' do
            expect(JSON.parse(response.body)).to contain_exactly('q1', 'q1/q1.txt', 'q2.txt')
          end
        end
      end
      context 'for a different assignment' do
        let(:starter_file_group) { create :starter_file_group }
        it 'should return a 404 error' do
          subject
          expect(response.status).to eq(404)
        end
      end
    end
    context 'when the starter code does not exist' do
      it 'should return a 404 error' do
        subject
        expect(response.status).to eq(404)
      end
    end
  end
  describe '#download_entries' do
    subject { get :download_entries, params: { assignment_id: assignment.id, id: starter_file_group.id || -1 } }
    let(:starter_file_group) { build :starter_file_group }
    include_examples 'unauthenticated request'
    context 'when the starter file exists' do
      context 'for this assignment' do
        let(:starter_file_group) { create :starter_file_group_with_entries, assignment: assignment }
        it 'should send a zip file containing the correct content' do
          expect(controller).to receive(:send_file) do |file_path|
            Zip::File.open(Rails.root + file_path) do |zipfile|
              expect(zipfile.entries.map(&:name)).to contain_exactly('q1/', 'q1/q1.txt', 'q2.txt')
              expect(zipfile.find_entry('q1/q1.txt').get_input_stream.read.strip).to eq 'q1 content'
              expect(zipfile.find_entry('q2.txt').get_input_stream.read.strip).to eq 'q2 content'
            end
          end
          subject
        end
      end
      context 'for a different assignment' do
        let(:starter_file_group) { create :starter_file_group }
        it 'should return a 404 error' do
          subject
          expect(response.status).to eq(404)
        end
      end
    end
    context 'when the starter code does not exist' do
      it 'should return a 404 error' do
        subject
        expect(response.status).to eq(404)
      end
    end
  end
end
