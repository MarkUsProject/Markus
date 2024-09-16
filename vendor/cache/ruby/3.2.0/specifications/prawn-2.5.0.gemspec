# -*- encoding: utf-8 -*-
# stub: prawn 2.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "prawn".freeze
  s.version = "2.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/prawnpdf/prawn/issues", "changelog_uri" => "https://github.com/prawnpdf/prawn/blob/2.5.0/CHANGELOG.md", "documentation_uri" => "https://prawnpdf.org/docs/prawn/2.5.0/", "homepage_uri" => "http://prawnpdf.org/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/prawnpdf/prawn" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Alexander Mankuta".freeze, "Gregory Brown".freeze, "Brad Ediger".freeze, "Daniel Nelson".freeze, "Jonathan Greenberg".freeze, "James Healy".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIC+jCCAeKgAwIBAgIBAzANBgkqhkiG9w0BAQsFADAjMSEwHwYDVQQDDBhhbGV4\nL0RDPXBvaW50bGVzcy9EQz1vbmUwHhcNMjMxMTA5MTA1MzIxWhcNMjQxMTA4MTA1\nMzIxWjAjMSEwHwYDVQQDDBhhbGV4L0RDPXBvaW50bGVzcy9EQz1vbmUwggEiMA0G\nCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDPOVLPGEK+eaP6zJfifrpWvPTg4qo3\nXNJJPom80SwqX2hVCVsRDK4RYgKUQqKRQzHhlx14wZHwWLETBVbNDGX3uqyCnTWU\nJUKh3ydiZShXpNHoV/NW7hhEYvNsDcBAjYTmbvXOhuYCo0Tz/0N2Oiun/0wIICtP\nvytY9TY0/lklWjAbsqJjNOu3o8IYkJBAN/rU96E/6WhFwjnxLcTnV9RfFRXdjG5j\nCughoB2xSwKX8gwbQ8fsnaZRmdyDGYNpz6sGF0zycfiLkTttbLA2nYATCALy98CH\nnsyZNsTjb4WINCuY2yEDjwesw9f/ROkNC68EgQ5M+aMjp+D0WcYGfzojAgMBAAGj\nOTA3MAkGA1UdEwQCMAAwCwYDVR0PBAQDAgSwMB0GA1UdDgQWBBRPgIwSVbeonua/\nNy/8576oxdUbrjANBgkqhkiG9w0BAQsFAAOCAQEAX28QLxNNz5EgaZZuQQUkbOXB\n4b5luBO22535+Vgj2jw7yjV8KKoGMWKrnB00ijgntqPEPXCzaPNibOcPZV5WfWVS\nt0Ls8lWE/8kezPwV4SbRe4Y7C+D4J+oirs0L5PtpREV9CJ7kfdW/AN9MtvjjBFlb\njHquD/MiOOMyHtuO0FiTL265m10thcAUsbyi0MehKgGbtJ5fGceHvZDqDouvbMjT\nhoijFk1oTY939JhjdcHuJzMiS2TrqIw8Dr5DkQu2vAjHpw0aOOWhlRjNJ7RHYJNm\nQugXmCnHQxSKTmc7imKuotyMdRRKFh8UEFCLRsFtBbNxkXyNuB4xBMuUYodhEw==\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2024-03-05"
  s.description = "Prawn is a fast, tiny, and nimble PDF generator for Ruby".freeze
  s.email = ["alex@pointless.one".freeze, "gregory.t.brown@gmail.com".freeze, "brad@bradediger.com".freeze, "dnelson@bluejade.com".freeze, "greenberg@entryway.net".freeze, "jimmy@deefa.com".freeze]
  s.homepage = "http://prawnpdf.org/".freeze
  s.licenses = ["Nonstandard".freeze, "GPL-2.0-only".freeze, "GPL-3.0-only".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "A fast and nimble PDF generator for Ruby".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<matrix>.freeze, ["~> 0.4"])
  s.add_runtime_dependency(%q<pdf-core>.freeze, ["~> 0.10.0"])
  s.add_runtime_dependency(%q<ttfunk>.freeze, ["~> 1.8"])
  s.add_development_dependency(%q<pdf-inspector>.freeze, [">= 1.2.1", "< 2.0.a"])
  s.add_development_dependency(%q<pdf-reader>.freeze, ["~> 1.4", ">= 1.4.1"])
  s.add_development_dependency(%q<prawn-dev>.freeze, ["~> 0.4.0"])
  s.add_development_dependency(%q<prawn-manual_builder>.freeze, ["~> 0.4.0"])
end
