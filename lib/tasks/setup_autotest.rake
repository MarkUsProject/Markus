# Rake task used to get initial information
# from the autotest server

namespace :markus do
  task setup_autotest: :environment do
    AutotestTestersJob.perform_now
  end
end
