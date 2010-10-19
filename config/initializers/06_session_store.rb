# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

# Please make sure, :session_key is named uniquely if you are hosting
# several MarkUs instances on one machine. Also, make sure you are changing
# the :secret string to something else than you find below.
ActionController::Base.session = {
  :key => MarkusConfigurator.markus_config_session_cookie_name,
  :secret      => MarkusConfigurator.markus_config_session_cookie_secret,
  :path => (ActionController::Base.relative_url_root.nil? or ActionController::Base.relative_url_root.empty?) ? '/' : ActionController::Base.relative_url_root,
  :expire_after => MarkusConfigurator.markus_config_session_cookie_expire_after,
  :http_only => MarkusConfigurator.markus_config_session_cookie_http_only,
  # if you use secure in Base.session, you will have to do an https connection,
  # but https is not implemented yet in MarkUs
  :secure => MarkusConfigurator.markus_config_session_cookie_secure
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store