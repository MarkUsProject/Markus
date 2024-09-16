# -*- encoding: utf-8 -*-
# stub: combine_pdf 1.0.26 ruby lib

Gem::Specification.new do |s|
  s.name = "combine_pdf".freeze
  s.version = "1.0.26"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Boaz Segev".freeze]
  s.date = "2023-12-22"
  s.description = "A nifty gem, in pure Ruby, to parse PDF files and combine (merge) them with other PDF files, number the pages, watermark them or stamp them, create tables, add basic text objects etc` (all using the PDF file format).".freeze
  s.email = ["bo@bowild.com".freeze]
  s.homepage = "https://github.com/boazsegev/combine_pdf".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Combine, stamp and watermark PDF files in pure Ruby.".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<ruby-rc4>.freeze, [">= 0.1.5"])
  s.add_runtime_dependency(%q<matrix>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest-around>.freeze, [">= 0"])
end
