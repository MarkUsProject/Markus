# Copyright 2008-2023  Sutou Kouhei <kou@cozmixng.org>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

begin
  require_relative "pkg-config/version"
rescue LoadError
end

require "English"
require "pathname"
require "rbconfig"
require "shellwords"

class PackageConfig
  class Error < StandardError
  end

  class NotFoundError < Error
  end

  SEPARATOR = File::PATH_SEPARATOR

  class << self
    @native_pkg_config = nil
    def native_pkg_config
      @native_pkg_config ||= guess_native_pkg_config
    end

    @native_pkg_config_prefix = nil
    def native_pkg_config_prefix
      @native_pkg_config_prefix ||= compute_native_pkg_config_prefix
    end

    @default_path = nil
    def default_path
      @default_path ||= compute_default_path
    end

    @custom_override_variables = nil
    def custom_override_variables
      @custom_override_variables ||= with_config("override-variables", "")
    end

    def clear_configure_args_cache
      @native_pkg_config = nil
      @native_pkg_config_prefix = nil
      @default_path = nil
      @custom_override_variables = nil
    end

    private
    def with_config(config, default=nil)
      if defined?(super)
        super
      else
        default
      end
    end

    def guess_native_pkg_config
      exeext = RbConfig::CONFIG["EXEEXT"]
      default_pkg_config = ENV["PKG_CONFIG"] || "pkg-config#{exeext}"
      pkg_config = with_config("pkg-config", default_pkg_config)
      pkg_config = Pathname.new(pkg_config)
      unless pkg_config.absolute?
        found_pkg_config = search_executable_from_path(pkg_config)
        pkg_config = found_pkg_config if found_pkg_config
      end
      unless pkg_config.absolute?
        found_pkg_config = search_pkg_config_by_dln_find_exe(pkg_config)
        pkg_config = found_pkg_config if found_pkg_config
      end
      pkg_config
    end

    def search_executable_from_path(name)
      (ENV["PATH"] || "").split(SEPARATOR).each do |path|
        try_name = Pathname(path) + name
        return try_name if try_name.executable?
      end
      nil
    end

    def search_pkg_config_by_dln_find_exe(pkg_config)
      begin
        require "dl/import"
      rescue LoadError
        return nil
      end
      dln = Module.new
      dln.module_eval do
        if DL.const_defined?(:Importer)
          extend DL::Importer
        else
          extend DL::Importable
        end
        begin
          dlload RbConfig::CONFIG["LIBRUBY"]
        rescue RuntimeError
          return nil if $!.message == "unknown error"
          return nil if /: image not found\z/ =~ $!.message
          raise
        rescue DL::DLError
          return nil
        end
        begin
          extern "const char *dln_find_exe(const char *, const char *)"
        rescue DL::DLError
          return nil
        end
      end
      path = dln.dln_find_exe(pkg_config.to_s, nil)
      if path.nil? or path.size.zero?
        nil
      else
        Pathname(path.to_s)
      end
    end

    def compute_native_pkg_config_prefix
      pkg_config = native_pkg_config
      return nil unless pkg_config.absolute?
      return nil unless pkg_config.exist?

      pkg_config_prefix = pkg_config.parent.parent
      if File::ALT_SEPARATOR
        normalized_pkg_config_prefix =
          pkg_config_prefix.to_s.split(File::ALT_SEPARATOR).join(File::SEPARATOR)
        Pathname(normalized_pkg_config_prefix)
      else
        pkg_config_prefix
      end
    end

    def compute_default_path
      default_paths = nil
      if native_pkg_config
        pc_path = run_command(native_pkg_config.to_s,
                              "--variable=pc_path",
                              "pkg-config")
        if pc_path
          default_paths = pc_path.strip.split(SEPARATOR)
          default_paths = nil if default_paths.empty?
        end
      end
      if default_paths.nil?
        arch_depended_path = Dir.glob("/usr/lib/*/pkgconfig")
        default_paths = []
        pkg_config_prefix = native_pkg_config_prefix
        if pkg_config_prefix
          pkg_config_arch_depended_paths =
            Dir.glob((pkg_config_prefix + "lib/*/pkgconfig").to_s)
          default_paths.concat(pkg_config_arch_depended_paths)
          default_paths << (pkg_config_prefix + "lib64/pkgconfig").to_s
          default_paths << (pkg_config_prefix + "libx32/pkgconfig").to_s
          default_paths << (pkg_config_prefix + "lib/pkgconfig").to_s
          default_paths << (pkg_config_prefix + "libdata/pkgconfig").to_s
          default_paths << (pkg_config_prefix + "share/pkgconfig").to_s
        end
        conda_prefix = ENV["CONDA_PREFIX"]
        if conda_prefix
          default_paths << File.join(conda_prefix, "lib", "pkgconfig")
        end
        default_paths << "/usr/local/lib64/pkgconfig"
        default_paths << "/usr/local/libx32/pkgconfig"
        default_paths << "/usr/local/lib/pkgconfig"
        default_paths << "/usr/local/libdata/pkgconfig"
        default_paths << "/usr/local/share/pkgconfig"
        default_paths << "/opt/local/lib/pkgconfig"
        default_paths.concat(arch_depended_path)
        default_paths << "/usr/lib64/pkgconfig"
        default_paths << "/usr/libx32/pkgconfig"
        default_paths << "/usr/lib/pkgconfig"
        default_paths << "/usr/libdata/pkgconfig"
        default_paths << "/usr/X11R6/lib/pkgconfig"
        default_paths << "/usr/X11R6/share/pkgconfig"
        default_paths << "/usr/X11/lib/pkgconfig"
        default_paths << "/opt/X11/lib/pkgconfig"
        default_paths << "/usr/share/pkgconfig"
      end
      if Object.const_defined?(:RubyInstaller)
        mingw_bin_path = RubyInstaller::Runtime.msys2_installation.mingw_bin_path
        mingw_pkgconfig_path = Pathname.new(mingw_bin_path) + "../lib/pkgconfig"
        default_paths.unshift(mingw_pkgconfig_path.cleanpath.to_s)
      end
      libdir = ENV["PKG_CONFIG_LIBDIR"]
      default_paths.unshift(libdir) if libdir

      paths = []
      if /-darwin\d[\d\.]*\z/ =~ RUBY_PLATFORM and
        /\A(\d+\.\d+)/ =~ run_command("sw_vers", "-productVersion")
        mac_os_version = $1
        homebrew_repository_candidates = []
        if pkg_config_prefix
          brew_path = pkg_config_prefix + "bin" + "brew"
          if brew_path.exist?
            homebrew_repository = run_command(brew_path.to_s, "--repository")
            if homebrew_repository
              homebrew_repository_candidates <<
                Pathname.new(homebrew_repository.strip)
            end
          else
            homebrew_repository_candidates << pkg_config_prefix + "Homebrew"
            homebrew_repository_candidates << pkg_config_prefix
          end
        end
        brew = search_executable_from_path("brew")
        if brew
          homebrew_repository = run_command("brew", "--repository")
          if homebrew_repository
          homebrew_repository_candidates <<
            Pathname(homebrew_repository.to_s)
          end
        end
        homebrew_repository_candidates.uniq.each do |candidate|
          pkgconfig_base_path = candidate + "Library/Homebrew/os/mac/pkgconfig"
          path = pkgconfig_base_path + mac_os_version
          unless path.exist?
            path = pkgconfig_base_path + mac_os_version.gsub(/\.\d+\z/, "")
          end
          paths << path.to_s if path.exist?
        end
      end
      paths.concat(default_paths)
      paths.join(SEPARATOR)
    end

    def run_command(*command_line)
      IO.pipe do |input, output|
        begin
          pid = spawn(*command_line,
                      out: output,
                      err: File::NULL)
          output.close
          _, status = Process.waitpid2(pid)
          return nil unless status.success?
          input.read
        rescue SystemCallError
          nil
        end
      end
    end
  end

  attr_reader :name
  attr_reader :paths
  attr_accessor :msvc_syntax
  def initialize(name, options={})
    if Pathname(name).absolute?
      @pc_path = name
      @path_position = 0
      @name = File.basename(@pc_path, ".*")
    else
      @pc_path = nil
      @path_position = nil
      @name = name
    end
    @options = options
    path = @options[:path] || ENV["PKG_CONFIG_PATH"]
    @paths = [path, self.class.default_path].compact.join(SEPARATOR).split(SEPARATOR)
    @paths.unshift(*(@options[:paths] || []))
    @paths = normalize_paths(@paths)
    @msvc_syntax = @options[:msvc_syntax]
    @variables = @declarations = nil
    override_variables = self.class.custom_override_variables
    @override_variables = parse_override_variables(override_variables)
    default_override_variables = @options[:override_variables] || {}
    @override_variables = default_override_variables.merge(@override_variables)
  end

  def exist?
    not pc_path.nil?
  end

  def requires
    parse_requires(declaration("Requires"))
  end

  def requires_private
    parse_requires(declaration("Requires.private"))
  end

  def cflags
    path_flags, other_flags = collect_cflags
    (other_flags + path_flags).join(" ")
  end

  def cflags_only_I
    collect_cflags[0].join(" ")
  end

  def cflags_only_other
    collect_cflags[1].join(" ")
  end

  def libs
    path_flags, other_flags = collect_libs
    (path_flags + other_flags).join(" ")
  end

  def libs_only_l
    collect_libs[1].find_all do |arg|
      if @msvc_syntax
        /\.lib\z/ =~ arg
      else
        /\A-l/ =~ arg
      end
    end.join(" ")
  end

  def libs_only_L
    collect_libs[0].find_all do |arg|
      if @msvc_syntax
        /\A\/libpath:/ =~ arg
      else
        /\A-L/ =~ arg
      end
    end.join(" ")
  end

  def version
    declaration("Version")
  end

  def description
    declaration("Description")
  end

  def variable(name)
    parse_pc if @variables.nil?
    expand_value(@override_variables[name] || @variables[name])
  end

  def declaration(name)
    parse_pc if @declarations.nil?
    expand_value(@declarations[name])
  end

  def pc_path
    if @pc_path
      return @pc_path if File.exist?(@pc_path)
    else
      @paths.each_with_index do |path, i|
        _pc_path = File.join(path, "#{@name}.pc")
        if File.exist?(_pc_path)
          @path_position = i + 1
          return _pc_path
        end
      end
    end
    nil
  end

  protected
  def path_position
    @path_position
  end

  def collect_requires(processed_packages={}, &block)
    packages = []
    targets = yield(self)
    targets.each do |name|
      next if processed_packages.key?(name)
      package = self.class.new(name, @options)
      processed_packages[name] = package
      packages << package
      packages.concat(package.collect_requires(processed_packages, &block))
    end
    packages_without_self = packages.reject do |package|
      package.name == @name
    end
    packages_without_self.uniq do |package|
      package.name
    end
  end

  private
  def sort_packages(packages)
    packages.sort_by.with_index do |package, i|
      [package.path_position, i]
    end
  end

  def collect_cflags
    target_packages = sort_packages([self, *all_required_packages])
    cflags_set = []
    target_packages.each do |package|
      cflags_set << package.declaration("Cflags")
    end
    all_cflags = normalize_cflags(Shellwords.split(cflags_set.join(" ")))
    path_flags, other_flags = all_cflags.partition {|flag| /\A-I/ =~ flag}
    path_flags = normalize_path_flags(path_flags, "-I")
    path_flags = path_flags.reject do |flag|
      flag == "-I/usr/include"
    end
    path_flags = path_flags.uniq
    if @msvc_syntax
      path_flags = path_flags.collect do |flag|
        flag.gsub(/\A-I/, "/I")
      end
    end
    [path_flags, other_flags]
  end

  def normalize_path_flags(path_flags, flag_option)
    return path_flags unless /-mingw(?:32|-ucrt)\z/ === RUBY_PLATFORM

    pkg_config_prefix = self.class.native_pkg_config_prefix
    return path_flags unless pkg_config_prefix

    mingw_dir = pkg_config_prefix.basename.to_s
    path_flags.collect do |path_flag|
      path = path_flag.sub(/\A#{Regexp.escape(flag_option)}/, "")
      path = path.sub(/\A\/#{Regexp.escape(mingw_dir)}/i) do
        pkg_config_prefix.to_s
      end
      "#{flag_option}#{path}"
    end
  end

  def normalize_cflags(cflags)
    normalized_cflags = []
    enumerator = cflags.to_enum
    begin
      loop do
        cflag = enumerator.next
        normalized_cflags << cflag
        case cflag
        when "-I"
          normalized_cflags << enumerator.next
        end
      end
    rescue StopIteration
    end
    normalized_cflags
  end

  def collect_libs
    target_packages = sort_packages(required_packages + [self])
    libs_set = []
    target_packages.each do |package|
      libs_set << package.declaration("Libs")
    end
    all_flags = split_lib_flags(libs_set.join(" "))
    path_flags, other_flags = all_flags.partition {|flag| /\A-L/ =~ flag}
    path_flags = normalize_path_flags(path_flags, "-L")
    path_flags = path_flags.reject do |flag|
      /\A-L\/usr\/lib(?:64|x32)?\z/ =~ flag
    end
    path_flags = path_flags.uniq
    if @msvc_syntax
      path_flags = path_flags.collect do |flag|
        flag.gsub(/\A-L/, "/libpath:")
      end
      other_flags = other_flags.collect do |flag|
        if /\A-l/ =~ flag
          "#{$POSTMATCH}.lib"
        else
          flag
        end
      end
    end
    [path_flags, other_flags]
  end

  def split_lib_flags(libs_command_line)
    all_flags = {}
    flags = []
    in_option = false
    libs_command_line.gsub(/-([Ll]) /, "\\1").split.each do |arg|
      if in_option
        flags << arg
        in_option = false
      else
        case arg
        when /-[lL]/
          next if all_flags.key?(arg)
          all_flags[arg] = true
          flags << arg
          in_option = true
        else
          flags << arg
        end
      end
    end
    flags
  end

  IDENTIFIER_RE = /[a-zA-Z\d_\.]+/
  def parse_pc
    raise NotFoundError, ".pc doesn't exist: <#{@name}>" unless exist?
    @variables = {}
    @declarations = {}
    File.open(pc_path) do |input|
      input.each_line do |line|
        line = line.gsub(/#.*/, "").strip
        next if line.empty?
        case line
        when /^(#{IDENTIFIER_RE})\s*=\s*/
          @variables[$1] = $POSTMATCH.strip
        when /^(#{IDENTIFIER_RE})\s*:\s*/
          @declarations[$1] = $POSTMATCH.strip
        end
      end
    end
  end

  def parse_requires(requires)
    return [] if requires.nil?
    requires_without_version = requires.gsub(/(?:<|>|<=|>=|=)\s*[\d.a-zA-Z_-]+\s*/, "")
    requires_without_version.split(/[,\s]+/)
  end

  def parse_override_variables(override_variables)
    variables = {}
    override_variables.split(",").each do |variable|
      name, value = variable.split("=", 2)
      variables[name] = value
    end
    variables
  end

  def expand_value(value)
    return nil if value.nil?
    value.gsub(/\$\{(#{IDENTIFIER_RE})\}/) do
      variable($1)
    end
  end

  def required_packages
    collect_requires do |package|
      package.requires
    end
  end

  def all_required_packages
    collect_requires do |package|
      package.requires_private + package.requires
    end
  end

  def normalize_paths(paths)
    paths.reject do |path|
      path.empty? or !File.exist?(path)
    end
  end
end

module PKGConfig
  @@paths = []
  @@override_variables = {}

  module_function
  def add_path(path)
    @@paths << path
  end

  def set_override_variable(key, value)
    @@override_variables[key] = value
  end

  def msvc?
    /mswin/.match(RUBY_PLATFORM) and /^cl\b/.match(RbConfig::CONFIG["CC"])
  end

  def package_config(package)
    PackageConfig.new(package,
                      :msvc_syntax => msvc?,
                      :override_variables => @@override_variables,
                      :paths => @@paths)
  end

  def exist?(pkg)
    package_config(pkg).exist?
  end

  def libs(pkg)
    package_config(pkg).libs
  end

  def libs_only_l(pkg)
    package_config(pkg).libs_only_l
  end

  def libs_only_L(pkg)
    package_config(pkg).libs_only_L
  end

  def cflags(pkg)
    package_config(pkg).cflags
  end

  def cflags_only_I(pkg)
    package_config(pkg).cflags_only_I
  end

  def cflags_only_other(pkg)
    package_config(pkg).cflags_only_other
  end

  def modversion(pkg)
    package_config(pkg).version
  end

  def description(pkg)
    package_config(pkg).description
  end

  def variable(pkg, name)
    package_config(pkg).variable(name)
  end

  def check_version?(pkg, major=0, minor=0, micro=0)
    return false unless exist?(pkg)
    ver = modversion(pkg).split(".").collect {|item| item.to_i}
    (0..2).each {|i| ver[i] = 0 unless ver[i]}

    (ver[0] > major ||
     (ver[0] == major && ver[1] > minor) ||
     (ver[0] == major && ver[1] == minor &&
      ver[2] >= micro))
  end

  def have_package(pkg, major=nil, minor=0, micro=0)
    message = "#{pkg}"
    unless major.nil?
      message << " version (>= #{major}.#{minor}.#{micro})"
    end
    major ||= 0
    result = checking_for(checking_message(message), "%s") do
      if check_version?(pkg, major, minor, micro)
        "yes (#{modversion(pkg)})"
      else
        if exist?(pkg)
          "no (#{modversion(pkg)}"
        else
          "no (nonexistent)"
        end
      end
    end
    enough_version = result.start_with?("yes")
    if enough_version
      libraries = libs_only_l(pkg)
      dldflags = libs(pkg)
      dldflags = (Shellwords.shellwords(dldflags) -
                  Shellwords.shellwords(libraries))
      dldflags = dldflags.map {|s| /\s/ =~ s ? "\"#{s}\"" : s }.join(" ")
      $libs   += " " + libraries
      if /mswin/ =~ RUBY_PLATFORM
        $DLDFLAGS += " " + dldflags
      else
        $LDFLAGS += " " + dldflags
      end
      $CFLAGS += " " + cflags_only_other(pkg)
      if defined?($CXXFLAGS)
        $CXXFLAGS += " " + cflags_only_other(pkg)
      end
      $INCFLAGS += " " + cflags_only_I(pkg)
    end
    enough_version
  end
end
