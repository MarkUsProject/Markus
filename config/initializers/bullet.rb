if Rails.env.development?
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.growl = false
  # Bullet.xmpp = { account:  'bullets_account@jabber.org',
  #                 password: 'bullets_password_for_jabber',
  #                 receiver: 'your_account@jabber.org',
  #                 show_online_status: true }
  Bullet.rails_logger = false
  Bullet.add_footer = true
  # Bullet.stacktrace_includes = [ 'your_gem', 'your_middleware' ]
  # Bullet.stacktrace_excludes = [ 'their_gem', 'their_middleware' ]
  # Bullet.slack = { webhook_url: 'http://some.slack.url', foo: 'bar' }
  Bullet.unused_eager_loading_enable = false
end
