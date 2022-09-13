class RemoveRelativeUrlRootFunction < ActiveRecord::Migration[7.0]
  def up
    execute %(
DROP FUNCTION IF EXISTS relative_url_root();

CREATE OR REPLACE FUNCTION database_identifier()
  RETURNS text AS
$$SELECT CONCAT((SELECT system_identifier FROM pg_control_system()), '-', (SELECT current_database FROM current_database()));$$
LANGUAGE sql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION get_authorized_keys()
RETURNS TABLE(authorized_keys text)
LANGUAGE plpgsql
AS
$$
DECLARE
  instance text;
BEGIN
  SELECT INTO instance database_identifier();
  RETURN QUERY SELECT CONCAT(
                'command="LOGIN_USER=',
                users.user_name,
                ' INSTANCE=',
                instance,
                ' markus-git-shell.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ',
                key_pairs.public_key)
  FROM key_pairs JOIN users ON key_pairs.user_id = users.id;
END
$$;
)
  end
  def down
    execute %(
DROP FUNCTION IF EXISTS database_identifier();

CREATE OR REPLACE FUNCTION relative_url_root()
  RETURNS text AS
$$SELECT text '/'$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION get_authorized_keys()
RETURNS TABLE(authorized_keys text)
LANGUAGE plpgsql
AS
$$
DECLARE
  instance text;
BEGIN
  SELECT INTO instance relative_url_root();
  RETURN QUERY SELECT CONCAT(
                'command="LOGIN_USER=',
                users.user_name,
                ' INSTANCE=',
                instance,
                ' markus-git-shell.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ',
                key_pairs.public_key)
  FROM key_pairs JOIN users ON key_pairs.user_id = users.id;
END
$$;
)
  end
end
