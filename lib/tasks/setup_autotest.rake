# Rake task used to get initial information
# from the autotest server

def setting_up_autotest?
  Rake.application.top_level_tasks.include?('markus:setup_autotest')
end

namespace :markus do
  task setup_autotest: :environment do
    include AutomatedTestsHelper::AutotestApi
    if File.exist? AUTOTEST_KEY_FILE
      update_credentials
    else
      register
    end
    schema
  end
end
