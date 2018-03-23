require 'repo/repository'

namespace :markus do
  desc 'Generates the repo permission file'
  task generate_repo_permissions: :environment do
    Repository.get_class.__set_all_permissions
  end
end
