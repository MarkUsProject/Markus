# Contains additional PostgreSQL statements not available in legacy migration class.
module MigrationHelpers
  # Applies foreign key constraints of the form:
  #   constraint fk_#{from_table}_#{to_table) foreign key from_column references to_table(id)
  def foreign_key(from_table, from_column, to_table)
    constraint_name = "fk_#{from_table}_#{to_table}"

    execute %{alter table #{from_table} add constraint #{constraint_name}
              foreign key (#{from_column}) references #{to_table} (id) on delete cascade}
  end

  # Applies foreign key constraints of the form:
  #   constraint fk_#{from_table}_#{to_table) foreign key from_column references to_table(id)
  # with no cascading delete
  def foreign_key_no_delete(from_table, from_column, to_table)
    constraint_name = "fk_#{from_table}_#{to_table}"

    execute %{alter table #{from_table} add constraint #{constraint_name}
              foreign key (#{from_column}) references #{to_table} (id)}
  end

  def delete_foreign_key(from_table, to_table)
    constraint_name = "fk_#{from_table}_#{to_table}"
    execute %(alter table #{from_table} drop constraint #{constraint_name})
  end
end
