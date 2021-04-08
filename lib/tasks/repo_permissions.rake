namespace :markus do
  task :repo_permissions, [:username, :repo_name] => :environment do |_task, args|
    exit 1 if args[:username].nil? || args[:repo_name].nil?
    include Repository
    exit 0 if AbstractRepository.get_full_access_users.include?(args[:username])
    exit 0 if AbstractRepository.get_all_permissions[args[:repo_name]].include?(args[:username])
    exit 1
  end
end
