# Configuration for the 'bullet' gem

if Rails.env.local?
  Rails.application.config.after_initialize do
    Bullet.enable = true
    # Bullet.sentry = true
    # Bullet.alert = true
    Bullet.bullet_logger = true
    # Bullet.console = true
    # Bullet.xmpp = { :account  => 'bullets_account@jabber.org',
    #                 :password => 'bullets_password_for_jabber',
    #                 :receiver => 'your_account@jabber.org',
    #                 :show_online_status => true }
    Bullet.rails_logger = true
    # Bullet.honeybadger = true
    # Bullet.bugsnag = true
    # Bullet.appsignal = true
    # Bullet.airbrake = true
    # Bullet.rollbar = true
    # Bullet.add_footer = true
    Bullet.skip_html_injection = true
    # Bullet.stacktrace_includes = [ 'your_gem', 'your_middleware' ]
    # Bullet.stacktrace_excludes = [ 'their_gem', ['my_file.rb', 'my_method'], ['my_file.rb', 16..20] ]
    # Bullet.slack = { webhook_url: 'http://some.slack.url', channel: '#default', username: 'notifier' }

    if Rails.env.test?
      Bullet.raise = true
    end

    # Detect N+1 queries
    Bullet.n_plus_one_query_enable = true

    # Detect eager-loaded associations which are not used
    Bullet.unused_eager_loading_enable = true

    # Detect unnecessary COUNT queries which could be avoided
    # with a counter_cache
    Bullet.counter_cache_enable = false
  end
end
