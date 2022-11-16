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
  # and connect to it for the duration of the block.
  # Note that the current database user must have permission to create additional databases
  def temporary_database(archve_db_name)
    ActiveRecord::Base.connection.execute("CREATE DATABASE #{archve_db_name}")
    old_db_config = ActiveRecord::Base.connection_db_config.configuration_hash.to_h
    archive_db = ActiveRecord::Base.establish_connection({ **old_db_config, database: archve_db_name })
    yield archive_db
  ensure
    archive_db.connection.disconnect!
    ActiveRecord::Base.establish_connection(old_db_config)
    ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{archve_db_name}")
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
  # If there are multiple classes stored in a given table (ie. single table inheritance), then
  # use the class that is the parent of all the others.
  def base_classes
    ApplicationRecord.descendants
                     .group_by(&:table_name)
                     .transform_values { |klasses| klasses.select { |k| (klasses - [k, *k.descendants]).empty? }.first }
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
      Rails.application.eager_load!

      table_names = ApplicationRecord.descendants.reject(&:abstract_class).group_by(&:table_name)

      archive_basename = "archive-#{course.name}"
      archive_dir = Rails.root.join("tmp/#{archive_basename}")
      FileUtils.rm_rf archive_dir
      FileUtils.mkdir_p archive_dir + 'db'
      FileUtils.mkdir_p archive_dir + 'data'
      FileUtils.cp Rails.root.join('db/structure.sql'), archive_dir + 'db/structure.sql'
      raw_connection = ActiveRecord::Base.connection.raw_connection

      table_names.each do |table_name, classes|
        ids = Set.new
        classes.each do |klass|
          # classes that have a has_one, has_many, or belongs_to association with Course
          class_ids = klass.joins(:course).where(courses: course).ids
          ids |= class_ids
        rescue ActiveRecord::ConfigurationError
          klass.reflect_on_all_associations.each do |assoc|
            if assoc.polymorphic?
              foreign_ids = klass.unscoped.distinct.pluck(assoc.foreign_type).map do |foreign_klass|
                foreign_klass.constantize.joins(:course).where(courses: course).ids
              rescue ActiveRecord::ConfigurationError
                # no association between the foreign class and course
              end.flatten
              class_ids = klass.where(assoc.foreign_key => foreign_ids).ids
            else
              begin
                class_ids = klass.joins(assoc.name => :course).where(assoc.name => { courses: course }).ids
              rescue ActiveRecord::ConfigurationError
                next
              end
            end
            ids |= class_ids
          end
        ensure
          archive_data_files(klass, class_ids, archive_dir + 'data') if defined?(class_ids)
        end
        next if ids.empty?
        File.open(archive_dir + "db/#{table_name}.csv", 'w') do |f|
          query = "COPY (SELECT * FROM #{table_name} WHERE id IN (#{ids.to_a.join(', ')})) TO STDOUT CSV HEADER"
          raw_connection.copy_data(query) do
            while (row = raw_connection.get_copy_data)
              f.write row
            end
          end
        end
      end

      zip_cmd = ['tar', '-czvf', "#{archive_dir}.tar.gz", archive_basename]
      Open3.capture2(*zip_cmd, chdir: Rails.root.join('tmp').to_s)
      FileUtils.rm_rf archive_dir
      puts "Course #{course.name} has been archived to #{archive_dir}.tar.gz"
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

      archve_db_name = "#{ActiveRecord::Base.connection_db_config.configuration_hash[:database]}_archive_restore"
      table_names = []
      table_load_order = []
      temporary_database(archve_db_name) do |archive_db|
        ActiveRecord::Base.connection.execute(File.read(File.join(db_dir, 'structure.sql')))
        raw_connection = archive_db.connection.raw_connection
        raw_connection.transaction do |conn|
          Dir[File.join(db_dir, '*.csv')].each do |db_file|
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
        temporary_file_storage(data_dir) { archive_db.connection.migration_context.migrate }
        # get table load order after loading into the temporary database because we need the records
        # present in the database to resolve polymorphic associations.
        table_load_order = load_order

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

      table_classes = base_classes
      new_ids = Hash.new { |h, k| h[k] = {} }
      errors_reported = false
      ActiveRecord.transaction do
        table_load_order.each do |table_name|
          db_file = File.join(db_dir, "#{table_name}.csv")
          next unless File.exist?(db_file)

          klass = table_classes[table_name]
          reverse_enums = klass.defined_enums.transform_values { |h| h.map { |k, v| [v&.to_s, k] }.to_h }
          foreign_keys = klass.reflect_on_all_associations.map do |association|
            if association.polymorphic?
              [association.foreign_key, [true, association.foreign_type]] # the association is polymorphic
            else
              [association.foreign_key, [false, association.klass.table_name]]
            end
          end.to_h
          CSV.parse(File.read(db_file), headers: true) do |row|
            attributes = row.map do |k, v|
              v = reverse_enums[k]&.[](v) || v # handle case where column is an enum value
              polymorphic, assoc_info = foreign_keys[k]
              unless polymorphic.nil?
                # get the table of the class in the "foreign_type" column if polymorphic, otherwise use the
                # (already calculated) table that the foreign key refers to
                foreign_table = polymorphic ? v[assoc_info].constantize.table_name : assoc_info
                v = new_ids[foreign_table][v]
              end
              [k, v]
            end.to_h.except('id')
            record = klass.new(attributes)
            if record.save
              new_id = record.id
              new_ids[table_name][row['id']] = new_id
              data_file = File.join(data_dir, "#{table_name}.#{row['id']}")
              if File.exist?(data_file)
                if record.respond_to? :_file_location
                  FileUtils.cp_r data_file, record._file_location
                else
                  warn "Unable to copy files associated with #{record.inspect}. " \
                       'This record does not have a _file_location method'
                  errors_reported = true
                end
              end
            elsif record.respond_to?(:course)
              warn "Unable to create record #{record.inspect}\nError(s): #{record.errors.full_messages.join(', ')}"
              errors_reported = true
            else
              u.attributes.slice(*u.errors.select { |e| e.type == :taken }.map { |e| e.attribute.to_s })
              taken_attrs = record.errors.select { |e| e.type == :taken }.map { |e| e.attribute.to_s }
              old_record = record.class.find_by(taken_attrs) # TODO: figure out if there can be multiple?
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
          ActiveRecord::Rollback unless gets.chomp == 'yes'
        end
      end
    ensure
      FileUtils.rm_rf archive_dir
    end
  end
end
