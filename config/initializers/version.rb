# read MarkUs version from app/MARKUS_VERSION and set it as a configuration variable

class VersionReader
  VERSION_REGEX = /master|v\d+\.\d+\.\d+/
  def self.read_version
    version_file = Rails.root.join('app/MARKUS_VERSION').expand_path
    unless File.exist?(version_file)
      return 'unknown'
    end
    content = File.new(version_file).read
    version_info = {}
    content.split(',').each do |token|
      k, v = token.split('=')
      version_info[k.downcase] = v
    end
    markus_version = version_info['version']
    raise "Invalid Version: #{markus_version}" unless VERSION_REGEX.match?(markus_version)
    Rails.configuration.markus_version = markus_version
  end
end

Rails.configuration.markus_version = VersionReader.read_version
