if Settings.repository.type == 'git'
  max_file_size_dir = ::Rails.root + 'lib' + 'repo' + 'git_hooks' + 'max_file_size'
  FileUtils.rm_rf(max_file_size_dir)
  FileUtils.mkdir_p(max_file_size_dir)

  Settings.map do |key, settings|
    max_file_size = settings.is_a?(Settings.class) && settings.max_file_size
    if max_file_size
      File.write(max_file_size_dir + key.to_s, max_file_size)
    end
  end

  File.write(max_file_size_dir + '.default', Settings.max_file_size)
end
