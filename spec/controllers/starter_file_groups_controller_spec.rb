describe StarterFileGroupsController do
  # TODO: add 'role is from a different course' shared tests to each route test below
  shared_examples 'student and ta not permitted' do
    before { subject }

    context 'a grader' do
      let(:role) { create(:ta) }

      it 'should not be permitted' do
        expect(response).to have_http_status :forbidden
      end
    end

    context 'a student' do
      let(:role) { create(:student) }

      it 'should not be permitted' do
        expect(response).to have_http_status :forbidden
      end
    end
  end

  shared_examples 'student not permitted but ta permitted' do
    before { subject }

    context 'a grader' do
      let(:role) { create(:ta) }

      it 'should be permitted' do
        expect(response).to have_http_status :ok
      end
    end

    context 'a student' do
      let(:role) { create(:student) }

      it 'should not be permitted' do
        expect(response).to have_http_status :forbidden
      end
    end
  end

  let(:role) { create(:instructor) }
  let(:assignment) { create(:assignment) }
  let(:course) { assignment.course }

  describe '#create' do
    subject { post_as role, :create, params: { name: 'b', assignment_id: assignment.id, course_id: course.id } }

    before { subject }

    it_behaves_like 'student and ta not permitted'

    it 'should create a new starter file group' do
      expect(assignment.reload.starter_file_groups).not_to be_empty
    end

    it 'should set the name' do
      expect(assignment.reload.starter_file_groups.first.name).to eq 'b'
    end
  end

  describe '#destroy' do
    subject { delete_as role, :destroy, params: { id: starter_file_group.id, course_id: course.id } }

    let(:starter_file_group) { create(:starter_file_group_with_entries, assignment: assignment) }

    it_behaves_like 'student and ta not permitted'

    it 'should delete the starter file group' do
      subject
      expect { starter_file_group.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#download_file' do
    subject do
      get_as role, :download_file, params: { file_name: filename,
                                             id: starter_file_group.id,
                                             course_id: course.id }
    end

    let(:starter_file_group) { create(:starter_file_group_with_entries, assignment: assignment) }
    let(:filename) { 'q2.txt' }

    before { subject }

    it_behaves_like 'student not permitted but ta permitted'

    context 'when a file exists' do
      it 'should download a file' do
        expect(response.body).to eq 'q2 content'
      end
    end

    context 'when a nested file exists' do
      let(:filename) { 'q1/q1.txt' }

      it 'should download a file' do
        expect(response.body).to eq 'q1 content'
      end
    end

    context 'when a file does not exist' do
      let(:filename) { 'q3.txt' }

      it 'should download a file with a warning message' do
        expect(response.body).to eq I18n.t('student.submission.missing_file', file_name: filename)
      end
    end

    context 'when the filename is invalid' do
      let(:filename) { '../../q2.txt' }

      it 'should download a file with a warning message' do
        expect(response.body).to eq(I18n.t('student.submission.missing_file', file_name: 'q2.txt'))
      end
    end
  end

  describe '#update' do
    subject { put_as role, :update, params: { name: 'b', course_id: course.id, id: starter_file_group.id } }

    let(:starter_file_group) { create(:starter_file_group_with_entries, assignment: assignment, name: 'a') }

    it_behaves_like 'student and ta not permitted'
    it 'can update the name' do
      subject
      expect(starter_file_group.reload.name).to eq 'b'
    end
  end

  describe '#download_files' do
    subject { get_as role, :download_files, params: { course_id: course.id, id: starter_file_group.id } }

    let(:starter_file_group) { create(:starter_file_group_with_entries, assignment: assignment, structure: {}) }

    it_behaves_like 'student not permitted but ta permitted'
    context 'when the starter file exists' do
      let(:starter_file_group) { create(:starter_file_group_with_entries, assignment: assignment) }

      it 'should send a zip file containing the correct content' do
        subject
        content = []
        Zip::InputStream.open(StringIO.new(response.body)) do |io|
          while (entry = io.get_next_entry)
            content << io.read.strip.force_encoding('utf-8') unless entry.name_is_directory?
          end
        end
        expect(content).to contain_exactly('q1 content', 'q2 content')
      end
    end

    context 'when the starter files do not exist' do
      it 'should send a zip file containing the correct content' do
        subject
        Zip::InputStream.open(StringIO.new(response.body)) do |io|
          expect(io.get_next_entry).to be_nil
        end
      end
    end
  end

  describe '#update_files' do
    subject do
      put_as role, :update_files, params: { course_id: course.id,
                                            id: starter_file_group.id,
                                            unzip: unzip,
                                            new_folders: new_folders,
                                            delete_folders: delete_folders,
                                            delete_files: delete_files,
                                            new_files: new_files }
    end

    let(:unzip) { true }
    let(:new_folders) { [] }
    let(:delete_folders) { [] }
    let(:delete_files) { [] }
    let(:new_files) { [] }
    let(:zipfile) { fixture_file_upload('test_zip.zip', 'application/zip') }
    let(:starter_file_group) { create(:starter_file_group_with_entries, assignment: assignment) }

    it_behaves_like 'student and ta not permitted'
    context 'uploading a zip file' do
      let(:new_files) { [zipfile] }
      let(:starter_file_group) { create(:starter_file_group_with_entries, assignment: assignment, structure: {}) }

      before { subject }

      context 'when unzip if false' do
        let(:unzip) { 'false' }

        it 'should upload the right files' do
          expect(starter_file_group.files_and_dirs).to contain_exactly('test_zip.zip')
        end

        it 'should create a new starter file entry' do
          expect(starter_file_group.starter_file_entries.pluck(:path)).to include('test_zip.zip')
        end
      end

      context 'when unzip if true' do
        it 'should upload the right files' do
          files = %w[test_zip test_zip/Shapes.java test_zip/zip_subdir test_zip/zip_subdir/TestShapes.java]
          expect(starter_file_group.files_and_dirs).to match_array(files)
        end

        it 'should create a new starter file entry' do
          expect(starter_file_group.starter_file_entries.pluck(:path)).to include('test_zip')
        end
      end
    end

    context 'uploading a folder' do
      let(:new_folders) { %w[new_folder q1/new_nested_folder] }

      before { subject }

      it 'should create a top level directory' do
        expect(starter_file_group.reload.files_and_dirs).to include('new_folder')
        expect(Dir.exist?(starter_file_group.path + 'new_folder')).to be true
      end

      it 'should create a new starter file entry' do
        expect(starter_file_group.starter_file_entries.pluck(:path)).to include('new_folder')
      end

      it 'should create a nested directory' do
        expect(starter_file_group.files_and_dirs).to include('q1/new_nested_folder')
        expect(Dir.exist?(starter_file_group.path + 'q1/new_nested_folder')).to be true
      end

      context 'when the folder path is invalid' do
        let(:new_folders) { %w[../../hello] }

        it 'flashes an error message' do
          expect(flash[:error]).to contain_message(I18n.t('errors.invalid_path'))
        end

        it 'does not create the folder' do
          expect(Dir).not_to exist(File.expand_path(File.join(assignment.autotest_files_dir, '../../hello')))
        end
      end
    end

    context 'deleting a file' do
      let(:delete_files) { %w[q2.txt q1/q1.txt] }

      before { subject }

      it 'should delete a top level file' do
        expect(starter_file_group.reload.files_and_dirs).not_to include('q2.txt')
        expect(File.exist?(starter_file_group.path + 'q2.txt')).to be false
      end

      it 'should delete a nested file' do
        expect(starter_file_group.reload.files_and_dirs).not_to include('q1/q1.txt')
        expect(File.exist?(starter_file_group.path + 'q1/q1.txt')).to be false
      end

      it 'should delete a starter file entry for the top level file' do
        expect(starter_file_group.starter_file_entries.pluck(:path)).not_to include('q2.txt')
      end

      it 'should not delete a starter file entry for the nested file' do
        expect(starter_file_group.starter_file_entries.pluck(:path)).to include('q1')
      end

      context 'when the file path is invalid' do
        let(:delete_files) { %w[../../../../../LICENSE] }

        it 'flashes an error message' do
          expect(flash[:error]).to contain_message(I18n.t('errors.invalid_path'))
        end

        it 'does not delete the file' do
          expect(File).to exist(File.expand_path(File.join(assignment.autotest_files_dir, '../../../../../LICENSE')))
        end
      end
    end

    context 'deleting a folder' do
      let(:delete_folders) { %w[q1 q2/q2] }
      let(:structure) { { 'q1/': nil, 'q2/q2/': nil, 'q2/q2/q2.txt': 'content' } }
      let(:starter_file_group) do
        create(:starter_file_group_with_entries, assignment: assignment, structure: structure)
      end

      before { subject }

      it 'should delete a top level folder' do
        expect(starter_file_group.reload.files_and_dirs).not_to include('q1')
        expect(Dir.exist?(starter_file_group.path + 'q1')).to be false
      end

      it 'should delete a nested folder' do
        expect(starter_file_group.reload.files_and_dirs).not_to include('q2/q2')
        expect(Dir.exist?(starter_file_group.path + 'q2/q2')).to be false
      end

      it 'should delete a starter file entry for the top level file' do
        expect(starter_file_group.starter_file_entries.pluck(:path)).not_to include('q1')
      end

      it 'should not delete a starter file entry for the nested file' do
        expect(starter_file_group.starter_file_entries.pluck(:path)).to include('q2')
      end

      context 'when the folder path is invalid' do
        let(:delete_folders) { %w[../../../../../doc] }

        it 'flashes an error message' do
          expect(flash[:error]).to contain_message(I18n.t('errors.invalid_path'))
        end

        it 'does not delete the folder' do
          expect(Dir).to exist(File.expand_path(File.join(assignment.autotest_files_dir, '../../../../../doc')))
        end
      end
    end

    context 'when the path is invalid' do
      subject do
        put_as role, :update_files, params: { course_id: course.id,
                                              id: starter_file_group.id,
                                              unzip: unzip,
                                              new_folders: new_folders,
                                              delete_folders: delete_folders,
                                              delete_files: delete_files,
                                              new_files: new_files,
                                              path: '../../' }
      end

      it 'should flash an error message' do
        subject
        expect(flash[:error]).to contain_message(I18n.t('errors.invalid_path'))
      end
    end
  end
end
