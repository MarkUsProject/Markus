# -*- encoding: utf-8 -*-
# stub: prawn-qrcode 0.5.2 ruby lib

Gem::Specification.new do |s|
  s.name = "prawn-qrcode".freeze
  s.version = "0.5.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jens Hausherr".freeze]
  s.date = "2020-06-16"
  s.description = "  Prawn/QRCode simplifies the generation and rendering of QRCodes in Prawn PDF documents.\n".freeze
  s.email = ["jabbrwcky@gmail.com".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "LICENSE".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "http://github.com/jabbrwcky/prawn-qrcode".freeze
  s.licenses = ["Apache License 2.0".freeze]
  s.rdoc_options = ["--title".freeze, "Prawn/QRCode Documentation--main".freeze, "README.md".freeze, "-q".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0".freeze)
  s.rubygems_version = "3.4.6".freeze
  s.summary = "Print QR Codes in PDF".freeze

  s.installed_by_version = "3.4.6" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<prawn>.freeze, [">= 1"])
  s.add_runtime_dependency(%q<rqrcode>.freeze, [">= 1.0.0"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.12", ">= 5.12.2"])
  s.add_development_dependency(%q<prawn-table>.freeze, ["~> 0.2.2"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.85.1"])
end
