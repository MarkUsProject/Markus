describe LtiKeyMaintenanceJob do
  describe '#perform' do
    context 'when rotation is disabled' do
      before { allow(Settings.lti.rotation).to receive(:enabled).and_return(false) }

      it 'does not rotate' do
        expect(LtiKeyStore).not_to receive(:rotate_if_due!)
        LtiKeyMaintenanceJob.perform_now
      end

      it 'does not prune' do
        expect(LtiKeyStore).not_to receive(:prune!)
        LtiKeyMaintenanceJob.perform_now
      end
    end

    context 'when rotation is enabled' do
      before { allow(Settings.lti.rotation).to receive(:enabled).and_return(true) }

      it 'rotates when due' do
        allow(LtiKeyStore).to receive(:prune!)
        expect(LtiKeyStore).to receive(:rotate_if_due!)
        LtiKeyMaintenanceJob.perform_now
      end

      it 'prunes retired keys' do
        allow(LtiKeyStore).to receive(:rotate_if_due!)
        expect(LtiKeyStore).to receive(:prune!)
        LtiKeyMaintenanceJob.perform_now
      end
    end
  end
end
