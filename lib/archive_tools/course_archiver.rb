module ArchiveTools
  module CourseArchiver
    # Create a temporary database using all the same connection parameters that we're using currently
    # and connect to it for the duration of the block. The temporary database will be dropped after the
    # block is exited.
    # Note that the current database user must have permission to create additional databases.
    # To connect to a pre-created database instead, pass a connection url as +tmp_db_url+.
    # Note that pre-created databases will not be dropped after the block exists so must be cleaned up manually.
    def temporary_database(archive_db_name, tmp_db_url: nil)
      old_db_config = ActiveRecord::Base.connection_db_config.configuration_hash.to_h
      if tmp_db_url.nil?
        ActiveRecord::Base.connection.execute("CREATE DATABASE #{archive_db_name}")
        archive_db = ActiveRecord::Base.establish_connection({ **old_db_config, database: archive_db_name })
      else
        archive_db = ActiveRecord::Base.establish_connection(tmp_db_url)
      end
      yield archive_db
    ensure
      archive_db.connection.disconnect!
      ActiveRecord::Base.establish_connection(old_db_config)
      ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{archive_db_name}") if tmp_db_url.nil?
    end

    # Change the file storage location to +tmp_dir+ for the duration of the block
    def temporary_file_storage(tmp_dir)
      old_settings = Settings.file_storage
      Settings.file_storage = Config::Options.new(default_root_path: tmp_dir)
      begin
        yield
      ensure
        Settings.file_storage = old_settings
      end
    end

    # Copy files associated with the records with class == klass and id in ids to the archive dir
    #
    # Files are found for a given record if the record has a _file_location method.
    #
    # In order to ensure that archived files can be recovered properly, _file_location should not
    # return a path with subdirectories that contain record ids.
    def archive_data_files(klass, ids, archive_dir)
      if klass.method_defined? :_file_location
        klass.where(id: ids).each do |record|
          new_loc = temporary_file_storage(archive_dir) { record._file_location }
          FileUtils.mkdir_p File.dirname(new_loc)
          FileUtils.cp_r(record._file_location, new_loc)
        end
      end
    end

    # Return the order that tables must be loaded into the database in order to make sure that tables referred
    # to by foreign keys are loaded before the tables that refer to them.
    # This method may raise an error if no defined order can be determined, ie. if there is a dependency cycle
    def load_order
      Rails.application.eager_load!
      dependencies = ApplicationRecord.descendants.reject(&:abstract_class).map do |klass|
        [klass.table_name,
         klass.reflect_on_all_associations(:belongs_to).map do |a|
           if a.polymorphic?
             klass.pluck(a.foreign_type).map(&:constantize).map(&:table_name)
           else
             a.klass.table_name
           end
         end.flatten]
      end
      dependencies = dependencies.group_by(&:first).transform_values { |v| v.map(&:second).flatten.uniq }

      load_order = []
      until dependencies.empty?
        added = 0
        dependencies.each do |k, deps|
          if deps.all? { |d| k == d || load_order.include?(d) }
            load_order << k
            dependencies.delete(k)
            added += 1
          end
        end
        raise "cycle detected in database table load order: #{dependencies}" if added.zero?
      end
      load_order
    end

    # Return a mapping from table names to the ActiveRecord class corresponding to the table.
    # If there are multiple classes stored in a given table (ie. single table inheritance) and +parent_only+ is true,
    # then use the class that is the parent of all the others.
    def table_classes(parent_only: true)
      Rails.application.eager_load!
      table_classes = ApplicationRecord.descendants.group_by(&:table_name)
      if parent_only
        table_classes.transform_values { |klasses| klasses.select { |k| (klasses - [k, *k.descendants]).empty? }.first }
      else
        table_classes
      end
    end

    # Return an array of ids of all records with class == +klass+ that are associated with the +course+
    # Records are associated with a given course if they have an association with the course either directly
    # or through another association.
    def ids_associated_to_course(course, klass)
      return [course.id] if klass == Course
      # classes that have a has_one, has_many, or belongs_to association with Course
      klass.joins(:course).where(courses: course).ids
    rescue ActiveRecord::ConfigurationError
      begin
        # classes that course has a has_many association to
        klass.joins(:courses).where(courses: course).ids
      rescue ActiveRecord::ConfigurationError
        class_ids = Set.new
        klass.reflect_on_all_associations.each do |assoc|
          if assoc.polymorphic?
            foreign_ids = klass.unscoped.distinct.pluck(assoc.foreign_type).map do |foreign_klass|
              foreign_klass.constantize.joins(:course).where(courses: course).ids
            rescue ActiveRecord::ConfigurationError
              # no association between the foreign class and course
            end.flatten
            class_ids |= klass.where(assoc.foreign_key => foreign_ids).ids
          else
            begin
              class_ids |= klass.joins(assoc.name => :course).where(assoc.name => { courses: course }).ids
            rescue ActiveRecord::ConfigurationError
              # no association between this class's associations and the course
            end
          end
        end
        class_ids.to_a
      end
    end

    # Return :d, :i, or nil indicating:
    #   - :d => directly associated to the Course class (either directly or through another association or
    #     has a .course instance method that returns the associated course),
    #   - :i => indirectly associated to the Course class (has an association that is directly associated to the
    #           Course class),
    #   - nil => not associated with the Course class
    #
    # Note that indirect associations where the intermediate direct association is polymorphic can only be detected if
    # there exists at least one record in the database that has that indirect association.
    # For example, if class X is associated to the Course class indirectly through one of classes Y or Z (where Y and Z
    # are polymorphic classes), then there needs to be at least one instance of X present that is associated with either
    # Y or Z.
    def association_type(klass, options = {})
      direct = klass.method_defined?(:course) || klass.reflect_on_all_associations.any? { |a| a.name == :course }
      return direct if options[:direct_only]
      return :d if direct
      klass.reflect_on_all_associations.each do |assoc|
        if assoc.polymorphic?
          foreign_types = klass.unscoped.distinct.pluck(assoc.foreign_type)
          return :i if foreign_types.any? { |k| association_type(k.constantize, direct_only: true) }
        elsif association_type(assoc.klass, direct_only: true)
          return :i
        end
      end
      nil
    end

    # Copy data from all csv files in +db_files+ to the database connected to by +raw_connection+
    # Data is copied to tables according to the file name, so data in foo.csv will be copied to the
    # table named foo
    def copy_from_csv_files(raw_connection, db_files)
      table_names = []
      raw_connection.transaction do |conn|
        db_files.each do |db_file|
          table_name = File.basename(db_file, '.csv')
          # disable the table triggers temporarily so that we can copy data in any order without
          # violating foreign key constraints
          conn.exec("ALTER TABLE #{table_name} DISABLE TRIGGER ALL")
          conn.copy_data("COPY #{table_name} FROM STDIN CSV HEADER") do
            File.read(db_file).each_line { |row| conn.put_copy_data row }
          end
          conn.exec("ALTER TABLE #{table_name} ENABLE TRIGGER ALL")
          FileUtils.rm db_file
          table_names << table_name
        end
      end
      table_names
    end

    # Extract the tar.gz archive in +archive_file+ to the +destination+ directory.
    # If the destination already exists it will be cleared before the archive
    # is extracted.
    # Note that this has been created to facilitate testing of the unarchive function.
    def extract_archive(archive_file, destination)
      FileUtils.rm_rf destination
      FileUtils.mkdir_p destination
      Open3.capture2('tar', '-xzvf', archive_file, '-C', destination.to_s)
    end

    # Archive the course named +course_name+. Return the absolute path to the tar.gz file
    # that contains the archived course data.
    def archive(course_name)
      course = Course.find_by(name: course_name)
      # Create a temporary directory to write database csv files and data files to
      archive_basename = "archive-#{course.name}"
      archive_dir = Rails.root.join("tmp/#{archive_basename}")
      begin
        FileUtils.rm_rf archive_dir
        FileUtils.mkdir_p [archive_dir + 'db', archive_dir + 'data']
        FileUtils.cp Rails.root.join('db/structure.sql'), archive_dir + 'db/structure.sql'

        table_classes(parent_only: false).each do |table_name, classes|
          ids = Set.new
          classes.each do |klass|
            class_ids = ids_associated_to_course(course, klass)
            ids |= class_ids
            archive_data_files(klass, class_ids, archive_dir + 'data')
          end
          next if ids.empty?
          File.open(archive_dir + "db/#{table_name}.csv", 'wb') do |f|
            # Order by id to ensure that rows with foreign key references to other rows in the same table get
            # created in the right order.
            query = "COPY (SELECT * FROM #{table_name} WHERE id IN (#{ids.to_a.join(', ')}) ORDER BY id) " \
                    'TO STDOUT CSV HEADER'
            ActiveRecord::Base.connection.raw_connection.copy_data(query) do
              while (row = ActiveRecord::Base.connection.raw_connection.get_copy_data)
                f.write row
              end
            end
          end
        end

        zip_cmd = ['tar', '-czvf', "#{archive_dir}.tar.gz", archive_basename]
        Open3.capture2(*zip_cmd, chdir: Rails.root.join('tmp').to_s)
        "#{archive_dir}.tar.gz"
      ensure
        FileUtils.rm_rf archive_dir
      end
    end

    # Unarchive the course whose data is contained in archive file. If +tmp_db_url+ is specified
    # use the database that can be connected to with that url as a temporary database used to migrate
    # data. If unspecified, a new temporary database will be created instead.
    def unarchive(archive_file, tmp_db_url: nil)
      archive_dir = Rails.root.join('tmp/unarchive-workspace')
      extract_archive(archive_file, archive_dir)

      db_dir = Dir[File.join(archive_dir, '*', 'db')].first
      raise 'db directory not found in tar file' if db_dir.nil?

      data_dir = Dir[File.join(archive_dir, '*', 'data')].first
      raise 'data directory not found in tar file' if data_dir.nil?

      archive_db_name = "#{ActiveRecord::Base.connection_db_config.configuration_hash[:database]}_archive_restore"
      table_load_order = []
      temporary_database(archive_db_name, tmp_db_url: tmp_db_url) do |archive_db|
        ActiveRecord::Base.connection.execute(File.read(File.join(db_dir, 'structure.sql')))
        raw_connection = archive_db.connection.raw_connection

        table_names = copy_from_csv_files(raw_connection, Dir[File.join(db_dir, '*.csv')])

        # migrate all the data up to the current migration. If migrations affect data files, access the files
        # in the data_dir directory.
        temporary_file_storage(data_dir) { archive_db.connection.migration_context.migrate }

        # get table load order after loading into the temporary database because we need the records
        # present in the database to resolve polymorphic associations.
        table_load_order = load_order

        # Copy files out of the temporary database back to csv files in the data dir now that all the data has
        # been migrated to the current migration
        table_names.each do |table_name|
          File.open(File.join(db_dir, "#{table_name}.csv"), 'wb') do |f|
            query = "COPY (SELECT * FROM #{table_name}) TO STDOUT CSV HEADER"
            raw_connection.copy_data(query) do
              while (row = raw_connection.get_copy_data)
                f.write row
              end
            end
          end
        end
      end

      table_class_mapping = table_classes
      new_ids = Hash.new { |h, k| h[k] = {} }
      errors_reported = false
      new_file_locations = []
      ApplicationRecord.transaction do
        table_load_order.each do |table_name|
          db_file = File.join(db_dir, "#{table_name}.csv")
          next unless File.exist?(db_file)

          parent_class = table_class_mapping[table_name]

          CSV.parse(File.read(db_file), headers: true) do |row|
            if (subclass_name = row[parent_class.inheritance_column]).nil?
              klass = parent_class
            else
              # Get the subclass if the current table uses single table inheritance
              klass = subclass_name.constantize
            end

            # transform columns with an enum value to the enum key so that ActiveRecord can use it
            reverse_enums = klass.defined_enums.transform_values { |h| h.map { |k, v| [v&.to_s, k] }.to_h }
            attributes = row.map { |k, v| [k, reverse_enums[k]&.[](v) || v] }.to_h
            record = klass.new(attributes)

            # Get the old file location before updating foreign keys so that file locations dependant on
            # foreign key values are calculated correctly. This works for files whose location is dependant
            # on foreign keys (eg: starter file group files), but not for files whose location is dependant
            # on associated records themselves (eg: group repositories); these are discovered after the new
            # record is created in the database.
            old_file_location = nil
            if record.respond_to? :_file_location
              old_file_location = temporary_file_storage(data_dir) { record._file_location }
            end

            # update foreign key references
            foreign_keys = klass.reflect_on_all_associations(:belongs_to).index_by(&:foreign_key)
            record.attributes.each do |k, v|
              association = foreign_keys[k]
              next if association.nil?

              if association.polymorphic?
                associated_class = record.attributes[association.foreign_type].constantize
              else
                associated_class = association.klass
              end
              record.assign_attributes(k => new_ids[associated_class.table_name][v.to_s])
            end

            if record.respond_to?(:_file_location) && !File.exist?(old_file_location.to_s)
              # The file may not exist if the location is dependant on the existence of an
              # associated object in the database (eg: group repositories' locations depend on
              # the course name). That object may not have existed yet the last time that
              # old_file_location was calculated
              old_file_location = temporary_file_storage(data_dir) { record._file_location }
            end

            # nullify the id so that it can be assigned a new one.
            # insert is used so that callbacks and validations are not run
            result = klass.insert(record.attributes.except('id'),
                                  returning: :id,
                                  record_timestamps: false)
            new_id = result.rows.flatten.first
            if !new_id.nil?
              new_ids[table_name][row['id']] = new_id
              unless old_file_location.nil?
                if File.exist? old_file_location
                  record = record.class.find(new_id)
                  new_file_location = record._file_location
                  if File.exist? new_file_location
                    # check this here because some files get created when the record is saved
                    warn "Cannot copy archived data files associated with #{record.inspect} to #{new_file_location}. " \
                         'A file or directory already exists at that path.'
                    errors_reported = true
                  else
                    # copy any associated files from the archived location to the new location on disk
                    FileUtils.mkdir_p(File.dirname(new_file_location))
                    FileUtils.cp_r(old_file_location, new_file_location)
                    new_file_locations << new_file_location
                  end
                else
                  warn "Cannot find archived data files associated with #{record.inspect}."
                  errors_reported = true
                end
              end
            elsif record.respond_to?(:course)
              warn "Unable to create record due to database conflict: #{record.inspect}"
              errors_reported = true
            else
              if klass.const_defined?(:IDENTIFIER)
                old_record = klass.find_by(record.attributes.slice(klass::IDENTIFIER))
              else
                old_record = nil
              end
              if old_record.nil?
                warn "Unable to create record due to database conflict: #{record.inspect}"
                errors_reported = true
              else
                new_ids[table_name][row['id']] = old_record.id
              end
            end
          end
        end
      rescue StandardError => e
        warn e.to_s
        errors_reported = true
      ensure
        if errors_reported
          begin
            if block_given?
              yield
            else
              raise ActiveRecord::Rollback
            end
          rescue ActiveRecord::Rollback
            new_file_locations.each { |loc| FileUtils.rm_rf loc }
            raise
          end
        end
      end
    ensure
      FileUtils.rm_rf archive_dir
    end

    # Remove course and all its data.
    # Only records directly associated with a given course will be removed.
    # Please archive the course first before deleting it! Course removal cannot be reversed except by
    # unarchiving a course.
    def remove_db_and_data(course_name)
      course = Course.find_by(name: course_name)
      id_hash = Hash.new { |h, k| h[k] = Set.new }
      table_classes(parent_only: false).each do |table_name, classes|
        classes.each do |klass|
          next unless klass == Course || association_type(klass, direct_only: true)
          ids = ids_associated_to_course(course, klass)
          id_hash[table_name] |= ids if ids.present?
        end
      end
      # Delete in reverse load order so that foreign key associations are never stranded
      table_class_mapping = table_classes(parent_only: true)
      load_order.reverse.each do |table_name|
        next unless id_hash.key? table_name
        klass = table_class_mapping[table_name]
        records = klass.where(id: id_hash[table_name])
        records.each { |record| FileUtils.rm_rf record._file_location } if klass.method_defined? :_file_location
        klass.descendants.each do |subclass|
          if subclass.method_defined? :_file_location
            records.where(klass.inheritance_column => subclass.name).each do |record|
              FileUtils.rm_rf record._file_location
            end
          end
        end
        records.delete_all
      end
    end
  end
end
