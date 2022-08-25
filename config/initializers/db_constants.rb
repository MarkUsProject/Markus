Rails.application.config.after_initialize do
  # Replace the relative_url_root function only if it already exists.
  #
  # This allows this procedure to run after the database is initialized but before the schema is loaded.
  # Otherwise if the function is created before schema is loaded then an error will be raised when loading the schema
  # because the relative_url_root() function already exists.
  relative_root_function = %(
  DO $_$
  BEGIN
      BEGIN
          PERFORM 'relative_url_root()'::regprocedure;
          CREATE OR REPLACE FUNCTION relative_url_root()
              RETURNS text AS
              $$SELECT text '#{ENV.fetch('RAILS_RELATIVE_URL_ROOT', '/')}'$$
              LANGUAGE sql IMMUTABLE PARALLEL SAFE;
      EXCEPTION WHEN undefined_function THEN
          NULL;
      END;
  END $_$;
  )
  ActiveRecord::Base.connection.execute(relative_root_function)
rescue ActiveRecord::NoDatabaseError
  warn 'Skipping initializing database constants because the database does not exist yet'
end
