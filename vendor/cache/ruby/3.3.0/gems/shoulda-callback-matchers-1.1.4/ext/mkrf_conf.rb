rbx = defined?(RUBY_ENGINE) && 'rbx' == RUBY_ENGINE

def already_installed(dep)
  !Gem::DependencyInstaller.new(domain: :local).find_gems_with_sources(dep).empty? ||
  !Gem::DependencyInstaller.new(domain: :local, prerelease: true).find_gems_with_sources(dep).empty?
end

if rbx
  require 'rubygems'
  require 'rubygems/command.rb'
  require 'rubygems/dependency.rb'
  require 'rubygems/dependency_installer.rb'

  begin
    Gem::Command.build_args = ARGV
    rescue NoMethodError
  end

  dep = [
    Gem::Dependency.new("rubysl", '~> 2.0'),
    Gem::Dependency.new("rubysl-test-unit", '~> 2.0'),
    Gem::Dependency.new("racc", '~> 1.4')
  ].reject{|d| already_installed(d) }

  begin
    puts "Installing base gem"
    inst = Gem::DependencyInstaller.new
    dep.each {|d| inst.install d }
  rescue
    inst = Gem::DependencyInstaller.new(prerelease: true)
    begin
      dep.each {|d| inst.install d }
    rescue Exception => e
      puts e
      puts e.backtrace.join "\n  "
      exit(1)
    end
  end unless dep.size == 0
end

# create dummy rakefile to indicate success
f = File.open(File.join(File.dirname(__FILE__), "Rakefile"), "w")
f.write("task :default\n")
f.close