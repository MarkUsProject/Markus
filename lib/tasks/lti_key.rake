namespace :markus do
  desc 'Generate a new LTI signing key and make it the current signer'
  task lti_key: :environment do
    puts "New current LTI key: #{LtiKeyStore.rotate!}"
  end

  desc 'Rotate the LTI signing key if the current one is past Settings.lti.rotation.max_age_days'
  task rotate_if_due: :environment do
    LtiKeyStore.rotate_if_due!
  end

  desc 'Remove retired LTI keys past Settings.lti.rotation.overlap_days'
  task prune_keys: :environment do
    LtiKeyStore.prune!
  end
end
