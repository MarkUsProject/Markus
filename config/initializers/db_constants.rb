Rails.application.config.after_initialize do
  relative_root_function = "CREATE OR REPLACE FUNCTION relative_url_root()
                          RETURNS text AS $$SELECT text '#{ENV.fetch('RAILS_RELATIVE_URL_ROOT', '/')}'$$
                          LANGUAGE sql IMMUTABLE PARALLEL SAFE;"
  ActiveRecord::Base.connection.execute(relative_root_function)
rescue ActiveRecord::NoDatabaseError
  warn 'Skipping initializing database constants because the database does not exist yet'
end
