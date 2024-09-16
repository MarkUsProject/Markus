# -*- encoding: utf-8 -*-
# stub: pdf-core 0.10.0 ruby lib

Gem::Specification.new do |s|
  s.name = "pdf-core".freeze
  s.version = "0.10.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/prawnpdf/pdf-core/issues", "changelog_uri" => "https://github.com/prawnpdf/pdf-core/blob/0.10.0/CHANGELOG.md", "documentation_uri" => "https://prawnpdf.org/docs/pdf-core/0.10.0/", "homepage_uri" => "http://prawnpdf.org/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/prawnpdf/pdf-core" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Alexander Mankuta".freeze, "Gregory Brown".freeze, "Brad Ediger".freeze, "Daniel Nelson".freeze, "Jonathan Greenberg".freeze, "James Healy".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDMjCCAhqgAwIBAgIBAjANBgkqhkiG9w0BAQsFADA/MQ0wCwYDVQQDDARhbGV4\nMRkwFwYKCZImiZPyLGQBGRYJcG9pbnRsZXNzMRMwEQYKCZImiZPyLGQBGRYDb25l\nMB4XDTIzMTIxMjE0Mzc0MFoXDTI0MTIxMTE0Mzc0MFowPzENMAsGA1UEAwwEYWxl\neDEZMBcGCgmSJomT8ixkARkWCXBvaW50bGVzczETMBEGCgmSJomT8ixkARkWA29u\nZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAM85Us8YQr55o/rMl+J+\nula89ODiqjdc0kk+ibzRLCpfaFUJWxEMrhFiApRCopFDMeGXHXjBkfBYsRMFVs0M\nZfe6rIKdNZQlQqHfJ2JlKFek0ehX81buGERi82wNwECNhOZu9c6G5gKjRPP/Q3Y6\nK6f/TAggK0+/K1j1NjT+WSVaMBuyomM067ejwhiQkEA3+tT3oT/paEXCOfEtxOdX\n1F8VFd2MbmMK6CGgHbFLApfyDBtDx+ydplGZ3IMZg2nPqwYXTPJx+IuRO21ssDad\ngBMIAvL3wIeezJk2xONvhYg0K5jbIQOPB6zD1/9E6Q0LrwSBDkz5oyOn4PRZxgZ/\nOiMCAwEAAaM5MDcwCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAwHQYDVR0OBBYEFE+A\njBJVt6ie5r83L/znvqjF1RuuMA0GCSqGSIb3DQEBCwUAA4IBAQCwy1p9OUw97QBi\nA4mp0YFfPx76ZAuBBy//POnstDu5tBPpaiE2pOC4Hr8d23QhQhi7TNHMhFbbviLN\n3PSD95fgZ5ZYiZWNUV5Z7IeDhpH3rWE070SH3PYfDKnzKewBn4KBLg2fGKm1HqsO\nUqvUp1HP0VdAUHTf3JsOaYg24GIN8f4Q6rIekG6C6z/MLkVLPHjh57y4jfdJkFMP\nLrBc0vY9enBMXykQjvnq1R4lD+2RkaAE2KwrjIPtPQR1mo9hPJvjWhvM+th1pk6E\nj+VZOY/0o89hstamSTBkvSK+kX7LhSX7ELlldyjQqPR1ZMmnznv2+1mVl733TfRl\nG3y/80js\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2024-03-05"
  s.description = "PDF::Core is used by Prawn to render PDF documents. It provides low-level format support.".freeze
  s.email = ["alex@pointless.one".freeze, "gregory.t.brown@gmail.com".freeze, "brad@bradediger.com".freeze, "dnelson@bluejade.com".freeze, "greenberg@entryway.net".freeze, "jimmy@deefa.com".freeze]
  s.homepage = "http://prawnpdf.org/".freeze
  s.licenses = ["Nonstandard".freeze, "GPL-2.0-only".freeze, "GPL-3.0-only".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Low level PDF generator.".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<pdf-inspector>.freeze, ["~> 1.1.0"])
  s.add_development_dependency(%q<pdf-reader>.freeze, ["~> 1.2"])
  s.add_development_dependency(%q<prawn-dev>.freeze, ["~> 0.4.0"])
end
