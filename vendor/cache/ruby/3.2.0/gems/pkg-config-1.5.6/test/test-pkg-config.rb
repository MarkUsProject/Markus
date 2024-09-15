require "mkmf"
require "pkg-config"

class PkgConfigTest < Test::Unit::TestCase
  def setup
    @custom_libdir = "/tmp/local/lib"
    options = {:override_variables => {"libdir" => @custom_libdir}}
    @cairo = PackageConfig.new("cairo", options)
    @cairo_png = PackageConfig.new("cairo-png", options)
  end

  def only_pkg_config_version(major, minor)
    pkg_config_version = `pkg-config --version`.chomp
    current_major, current_minor = pkg_config_version.split(".").collect(&:to_i)
    return if ([major, minor] <=> [current_major, current_minor]) <= 0
    omit("Require pkg-config #{pkg_config_version} or later")
  end

  def test_exist?
    assert(system("pkg-config --exists cairo"))
    assert(@cairo.exist?)

    assert(system("pkg-config --exists cairo-png"))
    assert(@cairo_png.exist?)
  end

  def test_cflags
    omit("Fragile on macOS") if RUBY_PLATFORM.include?("darwin")
    assert_pkg_config("cairo", ["--cflags"], @cairo.cflags)
    only_pkg_config_version(0, 29)
    assert_pkg_config("cairo-png", ["--cflags"], @cairo_png.cflags)
  end

  def test_cflags_only_I
    omit("Fragile on macOS") if RUBY_PLATFORM.include?("darwin")
    assert_pkg_config("cairo", ["--cflags-only-I"], @cairo.cflags_only_I)
    only_pkg_config_version(0, 29)
    assert_pkg_config("cairo-png", ["--cflags-only-I"], @cairo_png.cflags_only_I)
  end

  def split_lib_flags(libs_command_line)
    @cairo.__send__(:split_lib_flags, libs_command_line)
  end

  def test_split_libs
    assert_equal([
                   "-L/usr/local/Cellar/gtk+3/3.24.10/lib",
                   "-L/usr/local/Cellar/pango/1.44.3/lib",
                   "-L/usr/local/Cellar/harfbuzz/2.5.3/lib",
                   "-L/usr/local/Cellar/gdk-pixbuf/2.38.1_1/lib",
                   "-L/usr/local/Cellar/cairo/1.16.0_2/lib",
                   "-L/usr/local/Cellar/glib/2.60.6/lib",
                   "-L/usr/local/opt/gettext/lib",
                   "-lgdk-3",
                   "-framework", "Cocoa",
                   "-framework", "Carbon",
                   "-framework", "CoreGraphics",
                   "-lpangocairo-1.0",
                   "-lpango-1.0",
                   "-lharfbuzz",
                   "-lgdk_pixbuf-2.0",
                   "-lcairo-gobject",
                   "-lcairo",
                   "-lgobject-2.0",
                   "-lglib-2.0",
                   "-lintl"
                 ],
                 split_lib_flags("-L/usr/local/Cellar/gtk+3/3.24.10/lib " +
                                 "-L/usr/local/Cellar/pango/1.44.3/lib " +
                                 "-L/usr/local/Cellar/harfbuzz/2.5.3/lib " +
                                 "-L/usr/local/Cellar/gdk-pixbuf/2.38.1_1/lib " +
                                 "-L/usr/local/Cellar/cairo/1.16.0_2/lib " +
                                 "-L/usr/local/Cellar/glib/2.60.6/lib " +
                                 "-L/usr/local/opt/gettext/lib " +
                                 "-lgdk-3 " +
                                 "-framework Cocoa " +
                                 "-framework Carbon " +
                                 "-framework CoreGraphics " +
                                 "-lpangocairo-1.0 " +
                                 "-lpango-1.0 " +
                                 "-lharfbuzz " +
                                 "-lgdk_pixbuf-2.0 " +
                                 "-lcairo-gobject " +
                                 "-lcairo " +
                                 "-lgobject-2.0 " +
                                 "-lglib-2.0 " +
                                 "-lintl"))
  end

  def test_libs
    assert_pkg_config("cairo", ["--libs"], @cairo.libs)
    assert_pkg_config("cairo-png", ["--libs"], @cairo_png.libs)
  end

  def test_libs_msvc
    @cairo.msvc_syntax = true
    result = pkg_config("cairo", "--libs")
    msvc_result = result.gsub(/-lcairo\b/, "cairo.lib")
    msvc_result = msvc_result.gsub(/-L/, "/libpath:")
    assert_not_equal(msvc_result, result)
    assert_equal(msvc_result, @cairo.libs)
  end

  def test_libs_only_l
    assert_pkg_config("cairo", ["--libs-only-l"], @cairo.libs_only_l)
    assert_pkg_config("cairo-png", ["--libs-only-l"], @cairo_png.libs_only_l)
  end

  def test_libs_only_l_msvc
    @cairo_png.msvc_syntax = true
    result = pkg_config("cairo-png", "--libs-only-l")
    msvc_result = result.gsub(/-l(cairo|png[0-9]+|z)\b/, "\\1.lib")
    assert_not_equal(msvc_result, result)
    assert_equal(msvc_result, @cairo_png.libs_only_l)
  end

  def test_libs_only_L
    assert_pkg_config("cairo", ["--libs-only-L"], @cairo.libs_only_L)
    assert_pkg_config("cairo-png", ["--libs-only-L"], @cairo_png.libs_only_L)
  end

  def test_libs_only_L_msvc
    @cairo_png.msvc_syntax = true
    result = pkg_config("cairo-png", "--libs-only-L")
    msvc_result = result.gsub(/-L/, "/libpath:")
    assert_not_equal(msvc_result, result)
    assert_equal(msvc_result, @cairo_png.libs_only_L)
  end

  def test_requires
    assert_equal([], @cairo.requires)
  end

  def test_requires_private
    requires_private = pkg_config("cairo", "--print-requires-private")
    expected_requires = requires_private.split(/\n/).collect do |require|
      require.split(/\s/, 2)[0]
    end
    assert_equal(expected_requires,
                 @cairo.requires_private)
  end

  def test_version
    assert_pkg_config("cairo", ["--modversion"], @cairo.version)
  end

  def test_parse_override_variables
    assert_override_variables({}, nil)
    assert_override_variables({"prefix" => "c:\\\\gtk-dev"},
                              "prefix=c:\\\\gtk-dev")
    assert_override_variables({
                                "prefix" => "c:\\\\gtk-dev",
                                "includdir" => "d:\\\\gtk\\include"
                              },
                              ["prefix=c:\\\\gtk-dev",
                               "includdir=d:\\\\gtk\\include"].join(","))
  end

  def test_override_variables
    overridden_prefix = "c:\\\\gtk-dev"
    original_prefix = @cairo.variable("prefix")
    assert_not_equal(overridden_prefix, original_prefix)
    with_override_variables("prefix=#{overridden_prefix}") do
      cairo = PackageConfig.new("cairo")
      assert_equal(overridden_prefix, cairo.variable("prefix"))
    end
  end

  def test_not_found
    message = ".pc doesn't exist: <nonexistent>"
    assert_raise(PackageConfig::NotFoundError.new(message)) do
      PKGConfig.modversion("nonexistent")
    end
  end

  private
  def pkg_config(package, *args)
    args.unshift("--define-variable=libdir=#{@custom_libdir}")
    args = args.collect {|arg| arg.dump}.join(" ")
    normalize_pkg_config_result(`pkg-config #{args} #{package}`.strip)
  end

  def normalize_pkg_config_result(result)
    case RUBY_PLATFORM
    when /mingw/
      result = result.gsub(/\/bin\/..\//, "/")
      if result.include?(" -mms-bitfields ")
        # Reorder -mms-bitfields (non path flag)
        result = result.gsub(" -mms-bitfields ", " ")
        result = "-mms-bitfields #{result}"
      end
      result
    else
      result
    end
  end

  def assert_pkg_config(package, pkg_config_args, actual)
    result = pkg_config(package, *pkg_config_args)
    result = nil if result.empty?
    assert_equal(result, actual)
  end

  def assert_override_variables(expected, override_variables)
    with_override_variables(override_variables) do
      cairo = PackageConfig.new("cairo")
      assert_equal(expected, cairo.instance_variable_get("@override_variables"))
    end
  end

  def with_override_variables(override_variables)
    if override_variables.nil?
      args = {}
    else
      args = {"--with-override-variables" => override_variables}
    end
    PackageConfig.clear_configure_args_cache
    configure_args(args) do
      yield
    end
  end

  def configure_args(args)
    original_configure_args = $configure_args
    $configure_args = $configure_args.merge(args)
    yield
  ensure
    $configure_args = original_configure_args
  end

  sub_test_case("#parse_requires") do
    def parse_requires(requires)
      @cairo.__send__(:parse_requires, requires)
    end

    def test_broken_version
      assert_equal(["fribidi"],
                   parse_requires("fribidi >= fribidi_required_dep"))
    end
  
    def test_greater_than_or_equals_to
      assert_equal(["fribidi"],
                   parse_requires("fribidi >= 1.0"))
    end

    def test_greater_than
      assert_equal(["fribidi"],
                   parse_requires("fribidi > 1.0"))
    end

    def test_less_than_or_equals_to
      assert_equal(["fribidi"],
                   parse_requires("fribidi <= 1.0"))
    end

    def test_less_than
      assert_equal(["fribidi"],
                   parse_requires("fribidi < 1.0"))
    end

    def test_equals_to
      assert_equal(["fribidi"],
                   parse_requires("fribidi = 1.0"))
    end
  end
end
