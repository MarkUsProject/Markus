namespace :markus do
  namespace :repos do
    desc 'Destroy all repositories'
    task(drop: :environment) do
      puts "Destroying Repositories..."
      FileUtils.rm_r Dir.glob(File.join(Settings.repository.storage, '*'))
      if File.exist?(Repository::PERMISSION_FILE)
        File.delete(Repository::PERMISSION_FILE)
      end
    end

    desc 'Build repositories for all existing groups'
    task(build: :environment) do
      puts "Building Repositories for existing groups..."
      Group.all.each do |group|
        puts "Creating Repository for #{group.group_name}..."
        group.build_repository
      end
      puts "Creating Assignment folders..."
      Grouping.all.each do |grouping|
        grouping.create_starter_files
      end
    end
  end
end
