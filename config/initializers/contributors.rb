def read_contributors
  contributors_file = Rails.root.join('doc/markus-contributors.txt')
  if File.exist?(contributors_file)
    File.read(contributors_file).split("\n")
  else
    []
  end
end

Rails.configuration.markus_contributors = read_contributors
