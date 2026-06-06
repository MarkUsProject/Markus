describe GitRevision do
  context 'with a git repo' do
    let(:repo) { build(:git_repository) }

    before { FileUtils.rm_r(Dir.glob(File.join(Repository::ROOT_DIR, '*'))) }

    describe '#files_at_path' do
      # Commit a file named test in the workdir
      before do
        transaction = repo.get_transaction('dummy') # dummy user_id

        transaction.add('test', 'testdata')
        repo.commit(transaction)
      end

      it 'retrieves an object with the same name from the repo' do
        # Get latest revision's file in the working directory
        revision = repo.get_latest_revision
        files = revision.files_at_path('')

        expect(files).to include 'test'
      end

      it 'retrieves an object of type Repository::RevisionFile' do
        revision = repo.get_latest_revision
        files = revision.files_at_path('')
        test_file = files['test']
        # It should be the right type
        expect(test_file).to be_a Repository::RevisionFile
      end
      # retrieves objects not in the workdir
    end

    describe '#directories_at_path' do
      before do
        # Commit a file named test2 in a folder called testdir
        transaction = repo.get_transaction('dummy') # dummy user_id

        transaction.add('testdir/test', 'testdata')
        repo.commit(transaction)
      end

      it 'retrieves an object with the same name from the repo' do
        revision = repo.get_latest_revision
        directories = revision.directories_at_path('')
        expect(directories).to include 'testdir'
      end

      it 'retrieves an object of type Repository::RevisionDirectory' do
        revision = repo.get_latest_revision
        directories = revision.directories_at_path('')
        test_dir = directories['testdir']

        expect(test_dir).to be_a Repository::RevisionDirectory
      end
    end

    describe '#stringify' do
      before do
        transaction = repo.get_transaction('dummy') # dummy user_id

        transaction.add('test', 'testdata')
        repo.commit(transaction)
      end

      it 'gets the correct file data' do
        revision = repo.get_latest_revision
        files = revision.files_at_path('')
        test_file = files['test']

        expect(repo.stringify(test_file)).to eq 'testdata'
      end
    end

    describe '#entry_changed?' do
      let(:revision) { repo.get_latest_revision }

      def make_tree_double(file_oid)
        tree = instance_double(Rugged::Tree)
        if file_oid
          allow(tree).to receive(:path).and_return({ oid: file_oid })
        else
          allow(tree).to receive(:path).and_raise(Rugged::TreeError)
        end
        tree
      end

      def make_commit_double(file_oid, parents)
        instance_double(Rugged::Commit,
                        tree: make_tree_double(file_oid),
                        tree_id: file_oid,
                        parents: parents)
      end

      context 'for a regular (non-merge) commit' do
        it 'returns true when the file differs from the parent' do
          parent = make_commit_double('old_oid', [])
          commit = make_commit_double('new_oid', [parent])
          expect(revision.entry_changed?('file.txt', commit)).to be true
        end

        it 'returns false when the file is unchanged from the parent' do
          parent = make_commit_double('same_oid', [])
          commit = make_commit_double('same_oid', [parent])
          expect(revision.entry_changed?('file.txt', commit)).to be false
        end

        it 'returns true when the file is added (parent has no file)' do
          parent = make_commit_double(nil, [])
          commit = make_commit_double('new_oid', [parent])
          expect(revision.entry_changed?('file.txt', commit)).to be true
        end
      end

      context 'for a merge commit' do
        # Regression test for https://github.com/MarkUsProject/Markus/issues/4534:
        # when an instructor merges a student's commit into their own local branch and
        # pushes the merge commit, that merge commit should not be treated as the latest
        # "submission" for the student's files (which would inflate late penalties).
        it 'returns false when the result matches one parent (trivial merge)' do
          # parent_instructor has no student file; parent_student has the file;
          # the merge result simply carries forward parent_student's version.
          parent_instructor = make_commit_double(nil, [])
          parent_student = make_commit_double('student_file_oid', [])
          merge_commit = make_commit_double('student_file_oid', [parent_instructor, parent_student])
          expect(revision.entry_changed?('assignment/file.txt', merge_commit)).to be false
        end

        it 'returns true when the result differs from all parents (genuine conflict resolution)' do
          parent1 = make_commit_double('version_a', [])
          parent2 = make_commit_double('version_b', [])
          merge_commit = make_commit_double('version_c', [parent1, parent2])
          expect(revision.entry_changed?('assignment/file.txt', merge_commit)).to be true
        end

        it 'returns false when both parents have the same content' do
          parent1 = make_commit_double('same_oid', [])
          parent2 = make_commit_double('same_oid', [])
          merge_commit = make_commit_double('same_oid', [parent1, parent2])
          expect(revision.entry_changed?('assignment/file.txt', merge_commit)).to be false
        end
      end
    end
  end
end
