# -*- encoding: utf-8 -*-
# stub: fuubar 2.5.1 ruby lib

Gem::Specification.new do |s|
  s.name = "fuubar".freeze
  s.version = "2.5.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/thekompanee/fuubar/issues", "changelog_uri" => "https://github.com/thekompanee/fuubar/blob/master/CHANGELOG.md", "documentation_uri" => "https://github.com/thekompanee/fuubar/tree/releases/v2.4.0", "homepage_uri" => "https://github.com/thekompanee/fuubar", "source_code_uri" => "https://github.com/thekompanee/fuubar", "wiki_uri" => "https://github.com/thekompanee/fuubar/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nicholas Evans".freeze, "Jeff Kreeftmeijer".freeze, "jfelchner".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIEGDCCAoCgAwIBAgIBAjANBgkqhkiG9w0BAQsFADAyMTAwLgYDVQQDDCdhY2Nv\ndW50c19ydWJ5Z2Vtcy9EQz10aGVrb21wYW5lZS9EQz1jb20wHhcNMjAxMjI2MjIy\nNTE5WhcNMjExMjI2MjIyNTE5WjAyMTAwLgYDVQQDDCdhY2NvdW50c19ydWJ5Z2Vt\ncy9EQz10aGVrb21wYW5lZS9EQz1jb20wggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAw\nggGKAoIBgQD0Z84PxtE0iiWCMTQbnit6D4w55GGBQZnhpWUCJwC0SpQ/jnT0Fsma\ng8oAIdDclLvLC9jzqSAmkOujlpkJMb5NabgkhKFwHi6cVW/gz/cVnISAv8LQTIM5\nc1wyhwX/YhVFaNYNzMizB//kZOeXnv6x0tqV9NY7urHcT6mCwyLeNJIgf44i1Ut+\nmKtXxEyXNbfWQLVY95bVoVg3GOCkycerZN4Oh3zSJM1s+cZRBFlg7GR1AE3Xqs6k\nRhE7yp8ufeghC3bbxgnQrkk8W8Fkkl0/+2JAENpdE4OUepC6dFzDlLZ3UvSk7VHf\nNBRKSuO15kpPo2G55N0HLy8abUzbu5cqjhSbIk9hzD6AmdGCT4DqlsdHI5gOrGP0\nBO6VxGpRuRETKoZ4epPCsXC2XAwk3TJXkuuqYkgdcv8ZR4rPW2CiPvRqgG1YVwWj\nSrIy5Dt/dlMvxdIMiTj6ytAQP1kfdKPFWrJTIA2tspl/eNB+LiYsVdj8d0UU/KTY\ny7jqKMpOE1UCAwEAAaM5MDcwCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAwHQYDVR0O\nBBYEFO/l0LjdONn2Rr8y4WGyMA37MWVfMA0GCSqGSIb3DQEBCwUAA4IBgQDBGn+T\nHS7SCuLgjCimsT5e3v+Q0VaML1+yJPPqvIVM+HMyTYDpV2ogdAcX1I0lNbUHT9w7\n5y8pQ7BtYq8LDX6D8EufjvlgpJzunuPpNVh2QQdtkYC2zGabTnk+BJC5scYckBxW\nPxYXSuOxjXAkFe1r9RhPzeMY8lPVh6aEQKNLVkzbpIjoGzUgAPGPZG/ylKSWycwE\nqfHiDXzCAqMzSsb3sMQO1+0euciY1oTOyYCHYKo+gemWEI/p8PyJe/qB2tWC9GYs\nm+we5ul7O4Sq8qKnX0KCqHneqaXakcbuEkhViW6Def432jH8JjYums6EW2mg9570\npHS20TH4u9o0+5DIhayfGrmAtdtQutQNCclONqBlk7r3/16Y8Lr376dDHrISZlwd\nfdbUKgJXqJeb4GYhiKV07l67XExVjmAklMuA6bcB7mk+aSYUkoWNic4ZYGNjVv88\nAapqLKNG/UPfrJhdhTtFR4ARb8f54rgzONhTaAqVk23Bdp1yoDXaulFCkmU=\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2020-12-31"
  s.description = "the instafailing RSpec progress bar formatter".freeze
  s.email = ["jeff@kreeftmeijer.nl".freeze, "accounts+git@thekompanee.com".freeze]
  s.homepage = "https://github.com/thekompanee/fuubar".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.2.3".freeze
  s.summary = "the instafailing RSpec progress bar formatter".freeze

  s.installed_by_version = "3.5.11".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rspec-core>.freeze, ["~> 3.0".freeze])
  s.add_runtime_dependency(%q<ruby-progressbar>.freeze, ["~> 1.4".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7".freeze])
end
