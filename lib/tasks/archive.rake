namespace :markus do
  # Copy directory +src+ to +dest+. If +rev+ is true, instead
  # copy +dest+ to +src+. If +remove_dest+ is true, remove +dest+
  # before copying if it exists.
  def archive_copy(src, dest, rev: false, remove_dest: true)
    dest, src = [src, dest] if rev
    return unless Dir.exist?(src)

    FileUtils.rm_rf(dest) if remove_dest
    FileUtils.cp_r(src, dest)
  end

  # Copy all stateful MarkUs files to +archive_dir+. If +rev+ is
  # true, copy all files from +archive_dir+ to the locations specified
  # by the current MarkUs configuration.
  def copy_archive_files(archive_dir, rev: false)
    # copy repo permission file
    permission_file = archive_dir + 'permission_file'
    archive_copy(Repository::PERMISSION_FILE, permission_file.to_s, rev: rev)
    # copy log files
    log_dir = File.dirname(File.join(::Rails.root, Settings.logging.log_file))
    log_files_dir = archive_dir + 'log_files'
    archive_copy(log_dir, log_files_dir, rev: rev)
    # copy error files
    error_dir = File.dirname(File.join(::Rails.root, Settings.logging.error_file))
    error_files_dir = archive_dir + 'error_dir'
    archive_copy(error_dir, error_files_dir, rev: rev)
    # copy starter files
    starter_files_dir = archive_dir + 'starter_files'
    archive_copy(Assignment::STARTER_FILES_DIR, starter_files_dir, rev: rev)
    # copy autotest client dir
    autotest_dir = archive_dir + 'autotest_client'
    archive_copy(TestRun::SETTINGS_FILES_DIR, autotest_dir, rev: rev)
    # copy repositories
    repos_dir = archive_dir + 'repos'
    archive_copy(Repository::ROOT_DIR, repos_dir, rev: rev)
  end

  # Create a temporary database using all the same connection parameters that we're using currently
  # and connect to it for the duration of the block. The temporary database will be dropped after the
  # block is exited.
  # Note that the current database user must have permission to create additional databases.
  # To connect to a pre-created database instead, pass a connection url as the TMP_DB_URL environment variable.
  # Note that pre-created databases will not be dropped after the block exists so must be cleaned up manually.
  def temporary_database(archive_db_name)
    old_db_config = ActiveRecord::Base.connection_db_config.configuration_hash.to_h
    if (tmp_db_url = ENV.fetch('TMP_DB_URL', nil))
      archive_db = ActiveRecord::Base.establish_connection(tmp_db_url)
    else
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{archive_db_name}")
      archive_db = ActiveRecord::Base.establish_connection({ **old_db_config, database: archive_db_name })
    end
    yield archive_db
  ensure
    archive_db.connection.disconnect!
    ActiveRecord::Base.establish_connection(old_db_config)
    ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{archive_db_name}") if tmp_db_url
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
    dependencies = ApplicationRecord.descendants.reject(&:abstract_class).map do |r|
      [r.table_name,
       r.reflect_on_all_associations(:belongs_to).map do |a|
         if a.polymorphic?
           r.pluck(a.foreign_type).map(&:constantize).map(&:table_name)
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
  # If there are multiple classes stored in a given table (ie. single table inheritance) and +parent_only+ is true, then
  # use the class that is the parent of all the others.
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
    # classes that have a has_one, has_many, or belongs_to association with Course
    klass.joins(:course).where(courses: course).ids
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
    return true if direct && options[:direct_only]
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

  namespace :archive do
    # Copy all stateful MarkUs files to +archive_dir+
    task :files, [:archive_file] => :environment do |_task, args|
      archive_dir = Pathname.new("#{::Rails.root}/tmp/archive")
      FileUtils.rm_rf(archive_dir)
      FileUtils.mkdir_p(archive_dir)
      puts 'Copying files on disk'
      copy_archive_files(archive_dir)
      zip_file = File.expand_path(args[:archive_file])
      puts "Archiving all repositories and files to #{zip_file}"
      FileUtils.rm_f(zip_file)
      zip_cmd = ['tar', '-czvf', zip_file.to_s, '.']
      Open3.popen3(*zip_cmd, chdir: archive_dir)
    end

    task :course, [:course_name] => :environment do |_task, args|
      course = Course.find_by(name: args[:course_name])
      # Create a temporary directory to write database csv files and data files to
      archive_basename = "archive-#{course.name}"
      archive_dir = Rails.root.join("tmp/#{archive_basename}")
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
        File.open(archive_dir + "db/#{table_name}.csv", 'w') do |f|
          query = "COPY (SELECT * FROM #{table_name} WHERE id IN (#{ids.to_a.join(', ')})) TO STDOUT CSV HEADER"
          ActiveRecord::Base.connection.raw_connection.copy_data(query) do
            while (row = ActiveRecord::Base.connection.raw_connection.get_copy_data)
              f.write row
            end
          end
        end
      end

      zip_cmd = ['tar', '-czvf', "#{archive_dir}.tar.gz", archive_basename]
      Open3.capture2(*zip_cmd, chdir: Rails.root.join('tmp').to_s)
      puts "Course #{course.name} has been archived to #{archive_dir}.tar.gz"
    ensure
      FileUtils.rm_rf archive_dir
    end
  end

  namespace :unarchive do
    # Copy all stateful MarkUs files from +archive_dir+
    task :files, [:archive_file] => :environment do |_task, args|
      archive_dir = Pathname.new("#{::Rails.root}/tmp/archive")
      FileUtils.rm_rf(archive_dir)
      zip_file = args[:archive_file]
      puts "Unarchiving file #{zip_file}"
      zip_cmd = ['tar', '-xzvf', zip_file.to_s, '-C', archive_dir.to_s]
      Open3.popen3(*zip_cmd)
      puts 'Copying archived files to the app'
      copy_archive_files(archive_dir, rev: true)
    end
    task :course, [:archive_file] => :environment do |_task, args|
      archive_dir = Rails.root.join('tmp/unarchive-workspace')
      FileUtils.rm_rf archive_dir
      FileUtils.mkdir_p archive_dir
      Open3.capture2('tar', '-xzvf', args[:archive_file], '-C', archive_dir.to_s)

      db_dir = Dir[File.join(archive_dir, '*', 'db')].first
      raise 'db directory not found in tar file' if db_dir.nil?

      data_dir = Dir[File.join(archive_dir, '*', 'data')].first
      raise 'data directory not found in tar file' if data_dir.nil?

      archive_db_name = "#{ActiveRecord::Base.connection_db_config.configuration_hash[:database]}_archive_restore"
      table_load_order = []
      temporary_database(archive_db_name) do |archive_db|
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
          File.open(File.join(db_dir, "#{table_name}.csv"), 'w') do |f|
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
      ActiveRecord.transaction do
        table_load_order.each do |table_name|
          db_file = File.join(db_dir, "#{table_name}.csv")
          next unless File.exist?(db_file)

          klass = table_class_mapping[table_name]
          reverse_enums = klass.defined_enums.transform_values { |h| h.map { |k, v| [v&.to_s, k] }.to_h }

          foreign_keys = klass.reflect_on_all_associations(:belongs_to).index_by(&:foreign_key)

          CSV.parse(File.read(db_file), headers: true) do |row|
            # transform columns with an enum value to the enum key so that ActiveRecord can use it
            attributes = row.map { |k, v| [k, reverse_enums[k]&.[](v) || v] }.to_h
            record = klass.new(attributes)
            data_file = nil
            if record.respond_to? :_file_location
              data_file = temporary_file_storage(data_dir) { record._file_location }
            end

            # update foreign key references
            record.attributes.each do |k, v|
              association = foreign_keys[k]
              next if association.nil?

              if association.polymorphic?
                associated_class = record.attributes[association.foreign_type].constantize
              else
                associated_class = association.klass
              end
              record.assign_attributes(k => new_ids[associated_class.table_name][v])
            end
            # nullify the id so that it can be assigned a new one on save
            record.id = nil
            if record.save
              # save the new id so that future records with associations to this record can refer to its new id
              new_ids[table_name][row['id']] = record.id
              if record.respond_to?(:_file_location)
                # copy any associated files from the archived location to the new location on disk
                if !data_file.nil? && File.exist?(data_file)
                  new_location = record._file_location
                  if File.exist?(new_location)
                    warn "Cannot copy archived data files associated with #{record.inspect} to #{new_location}. " \
                         'A file or directory already exists at that path.'
                    errors_reported = true
                  else
                    FileUtils.mkdir_p(File.dirname(new_location))
                    FileUtils.cp_r(data_file, new_location)
                    new_file_locations << new_location
                  end
                else
                  warn "Cannot find archived data files associated with #{record.inspect}."
                  errors_reported = true
                end
              end
            elsif record.respond_to?(:course)
              warn "Unable to create record #{record.inspect}\nError(s): #{record.errors.full_messages.join(', ')}"
              errors_reported = true
            else
              taken_attrs = record.errors
                                  .select { |e| e.type == :taken }
                                  .map { |e| [e.attribute, e.options[:value]] }
                                  .to_h
              old_record = record.class.find_by(taken_attrs)
              if old_record.nil?
                warn "Unable to create record #{record.inspect}\nError(s): #{record.errors.full_messages.join(', ')}"
                errors_reported = true
              else
                new_ids[table_name][row['id']] = old_record.id
              end
            end
          end
        end
      ensure
        if errors_reported
          warn "Do you want to commit all changes even though there were some errors reported? Type 'yes' to confirm."
          unless gets.chomp == 'yes'
            new_file_locations.each { |loc| FileUtils.rm_rf loc }
            raise ActiveRecord::Rollback
          end
        end
      end
    ensure
      FileUtils.rm_rf archive_dir
    end
  end
end
