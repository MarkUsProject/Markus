if Settings.repository.type == 'git'
  max_file_size_file = ::Rails.root + 'lib' + 'repo' + 'git_hooks' + 'max_file_size'
  File.open(max_file_size_file, 'w') { |f| f.write(Settings.max_file_size) }
end
