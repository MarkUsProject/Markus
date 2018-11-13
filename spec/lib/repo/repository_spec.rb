describe Repository::AbstractRepository do
  context 'repository permissions should be updated' do
    context 'exactly once' do
      it 'for a single update' do
        expect(Repository.get_class).to receive(:__update_permissions).once
        Repository.get_class.update_permissions
      end
      it 'at the end of a batch update' do
        expect(Repository.get_class).to receive(:__update_permissions).once
        Repository.get_class.update_permissions_after {}
      end
      it 'at the end of a batch update only if requested' do
        expect(Repository.get_class).to receive(:__update_permissions).once
        Repository.get_class.update_permissions_after(only_on_request: true) { Repository.get_class.update_permissions }
      end
      context 'by the last thread to read from the database' do
        it 'when there are multiple concurrent updates' do
          expect(Repository.get_class).to receive(:__update_permissions).once
          threads = []
          2.times { threads << Thread.new { Repository.get_class.update_permissions } }
          threads.each(&:join)
        end
        it 'when there are multiple concurrent batch updates' do
          expect(Repository.get_class).to receive(:__update_permissions).once
          threads = []
          2.times { threads << Thread.new { Repository.get_class.update_permissions_after {} } }
          threads.each(&:join)
        end
      end
    end
    context 'multiple times' do
      it 'for multiple updates made by the same thread' do
        expect(Repository.get_class).to receive(:__update_permissions).twice
        Repository.get_class.update_permissions
        Repository.get_class.update_permissions
      end
    end
  end
  context 'repository permissions should not be updated' do
    it 'when not in authoritative mode' do
      allow(MarkusConfigurator).to receive(:markus_config_repository_admin?).and_return(false)
      expect(Repository.get_class).not_to receive(:__update_permissions)
      Repository.get_class.update_permissions
    end
    it 'at the end of a batch update if not requested' do
      expect(Repository.get_class).not_to receive(:__update_permissions)
      Repository.get_class.update_permissions_after(only_on_request: true) {}
    end
  end
end
