return if defined?(setting_up_autotest?) && setting_up_autotest?

Rails.configuration.to_prepare do
  if Settings.autotest.enable && !File.exist?(AutomatedTestsHelper::AutotestApi::AUTOTEST_KEY_FILE)
    STDERR.puts 'MARKUS WARNING: Autotesting is enabled but has not been set up yet.' \
                'Either disable autotesting or run the markus:setup_autotest rake task to set up autotesting.'
  end
end
