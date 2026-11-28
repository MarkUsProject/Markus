# Capybara 3.40.0 clears browser data between tests with the '*' origin, which Chrome 158 rejects
# (https://github.com/teamcapybara/capybara/issues/2865). When that happens, clear every cookie and
# the app's local storage instead. Remove this patch once Capybara releases a fix.
module CapybaraChromeReset
  def reset!
    super
  rescue Selenium::WebDriver::Error::InvalidArgumentError => e
    raise unless e.message.include?('* is not a valid URL')

    execute_cdp('Network.clearBrowserCookies')
    execute_cdp('Storage.clearDataForOrigin', origin: Capybara.app_host, storageTypes: 'local_storage')
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(CapybaraChromeReset)
