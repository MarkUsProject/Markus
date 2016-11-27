namespace :markus do
  desc "Generates a Gitolite permission file (gitolite.conf)"
  task(generate_git_authz: [:environment]) do
    GitRepository.__set_all_permissions
  end
end
