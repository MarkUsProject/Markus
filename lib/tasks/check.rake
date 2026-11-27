namespace :markus do
  desc 'Check that MarkUs is configured correctly and that the dependencies of enabled features are installed.'
  task check: :environment do
    success = InstallationCheck.new.run
    $stdout.flush
    abort 'MarkUs installation check failed (see [FAIL] messages above).' unless success
  end
end
