describe Repository::AbstractRepository do
  context 'repository permissions should be updated' do
    context 'exactly once' do
      it 'for a single update' do
        expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
        Repository.get_class.update_permissions
      end
      it 'at the end of a batch update' do
        expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
        Repository.get_class.update_permissions_after {}
      end
      it 'at the end of a batch update only if requested' do
        expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
        Repository.get_class.update_permissions_after(only_on_request: true) { Repository.get_class.update_permissions }
      end
    end
    context 'multiple times' do
      it 'for multiple updates made by the same thread' do
        expect(UpdateRepoPermissionsJob).to receive(:perform_later).twice
        Repository.get_class.update_permissions
        Repository.get_class.update_permissions
      end
    end
  end
  context 'repository permissions should not be updated' do
    it 'when not in authoritative mode' do
      allow(Settings.repository).to receive(:is_repository_admin).and_return(false)
      expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
      Repository.get_class.update_permissions
    end
    it 'at the end of a batch update if not requested' do
      expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
      Repository.get_class.update_permissions_after(only_on_request: true) {}
    end
  end
end
