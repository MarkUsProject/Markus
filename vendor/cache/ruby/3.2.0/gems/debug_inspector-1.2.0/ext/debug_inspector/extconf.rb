def fake_makefile
  File.open("Makefile", "w") { |f|
    f.puts '.PHONY: install'
    f.puts 'install:'
    f.puts "\t" + '@echo "This Ruby not supported by/does not require debug_inspector."'
  }
end

def can_compile_extensions?
  RUBY_ENGINE == "ruby" or RUBY_ENGINE == "truffleruby"
end

if can_compile_extensions?
  require 'mkmf'
  create_makefile('debug_inspector')
else
  fake_makefile
end
