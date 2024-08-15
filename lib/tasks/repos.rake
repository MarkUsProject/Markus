namespace :markus do
  namespace :repos do
    desc 'Destroy all repositories'
    task(drop: :environment) do
      puts 'Destroying Repositories...'
      FileUtils.rm_r Dir.glob(File.join(Repository::ROOT_DIR, '*'))
      FileUtils.rm_f(Repository::PERMISSION_FILE)
    end

    desc 'Build repositories for all existing groups'
    task(build: :environment) do
      puts 'Building Repositories for existing groups...'
      Group.find_each do |group|
        puts "Creating Repository for #{group.group_name}..."
        group.build_repository
      end
      puts 'Creating Assignment folders...'
      Grouping.find_each(&:create_starter_files)
    end
  end
end
