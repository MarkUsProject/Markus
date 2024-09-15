# -*- encoding: utf-8 -*-
# stub: kgio 2.11.4 ruby lib
# stub: ext/kgio/extconf.rb

Gem::Specification.new do |s|
  s.name = "kgio".freeze
  s.version = "2.11.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["kgio hackers".freeze]
  s.date = "2021-05-25"
  s.description = "This is a legacy project, do not use it for new projects.  Ruby\n2.3 and later should make this obsolete.  kgio provides\nnon-blocking I/O methods for Ruby without raising exceptions on\nEAGAIN and EINPROGRESS.\n".freeze
  s.email = "kgio-public@yhbt.net".freeze
  s.extensions = ["ext/kgio/extconf.rb".freeze]
  s.extra_rdoc_files = ["LICENSE".freeze, "README".freeze, "TODO".freeze, "NEWS".freeze, "LATEST".freeze, "ISSUES".freeze, "HACKING".freeze, "ext/kgio/accept.c".freeze, "ext/kgio/autopush.c".freeze, "ext/kgio/connect.c".freeze, "ext/kgio/kgio_ext.c".freeze, "ext/kgio/poll.c".freeze, "ext/kgio/wait.c".freeze, "ext/kgio/tryopen.c".freeze]
  s.files = ["HACKING".freeze, "ISSUES".freeze, "LATEST".freeze, "LICENSE".freeze, "NEWS".freeze, "README".freeze, "TODO".freeze, "ext/kgio/accept.c".freeze, "ext/kgio/autopush.c".freeze, "ext/kgio/connect.c".freeze, "ext/kgio/extconf.rb".freeze, "ext/kgio/kgio_ext.c".freeze, "ext/kgio/poll.c".freeze, "ext/kgio/tryopen.c".freeze, "ext/kgio/wait.c".freeze]
  s.homepage = "https://yhbt.net/kgio/".freeze
  s.licenses = ["LGPL-2.1+".freeze]
  s.rubygems_version = "3.4.6".freeze
  s.summary = "kinder, gentler I/O for Ruby".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<test-unit>.freeze, ["~> 3.0"])
end
