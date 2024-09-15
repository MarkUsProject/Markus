# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'pdf-core'
  spec.version = '0.10.0'
  spec.platform = Gem::Platform::RUBY
  spec.summary = 'Low level PDF generator.'
  spec.description = 'PDF::Core is used by Prawn to render PDF documents. It provides low-level format support.'
  spec.files =
    Dir.glob('lib/**/**/*') +
    %w[COPYING GPLv2 GPLv3 LICENSE] +
    ['pdf-core.gemspec']
  spec.require_path = 'lib'
  spec.required_ruby_version = '>= 2.7'
  spec.required_rubygems_version = '>= 1.3.6'

  if File.basename($PROGRAM_NAME) == 'gem' && ARGV.include?('build')
    signing_key = File.expand_path('~/.gem/gem-private_key.pem')
    if File.exist?(signing_key)
      spec.cert_chain = ['certs/pointlessone.pem']
      spec.signing_key = signing_key
    else
      warn 'WARNING: Signing key is missing. The gem is not signed and its authenticity can not be verified.'
    end
  end

  spec.authors = [
    'Alexander Mankuta', 'Gregory Brown', 'Brad Ediger', 'Daniel Nelson',
    'Jonathan Greenberg', 'James Healy',
  ]
  spec.email = [
    'alex@pointless.one', 'gregory.t.brown@gmail.com', 'brad@bradediger.com',
    'dnelson@bluejade.com', 'greenberg@entryway.net', 'jimmy@deefa.com',
  ]
  spec.licenses = %w[Nonstandard GPL-2.0-only GPL-3.0-only]
  spec.homepage = 'http://prawnpdf.org/'
  spec.metadata = {
    'rubygems_mfa_required' => 'true',
    'homepage_uri' => spec.homepage,
    'changelog_uri' => "https://github.com/prawnpdf/pdf-core/blob/#{spec.version}/CHANGELOG.md",
    'source_code_uri' => 'https://github.com/prawnpdf/pdf-core',
    'documentation_uri' => "https://prawnpdf.org/docs/pdf-core/#{spec.version}/",
    'bug_tracker_uri' => 'https://github.com/prawnpdf/pdf-core/issues',
  }
  spec.add_development_dependency('pdf-inspector', '~> 1.1.0')
  spec.add_development_dependency('pdf-reader', '~>1.2')
  spec.add_development_dependency('prawn-dev', '~> 0.4.0')
end
