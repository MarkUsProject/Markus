if Settings.repository.type == 'git'
  max_file_size_dir = ::Rails.root + 'lib' + 'repo' + 'git_hooks' + 'max_file_size'

  FileUtils.rm_rf(max_file_size_dir)
  FileUtils.mkdir_p(max_file_size_dir)

  Settings.map do |key, settings|
    max_file_size = settings.is_a?(Settings.class) && settings.max_file_size
    if max_file_size
      File.open(max_file_size_dir + key.to_s, 'w') { |f| f.write(max_file_size) }
    end
  end

  File.open(max_file_size_dir + '.default', 'w') { |f| f.write(Settings.max_file_size) }
end
