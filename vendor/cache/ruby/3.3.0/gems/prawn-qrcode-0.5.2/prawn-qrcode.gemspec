# Copyright 2011 - 2019 Jens Hausherr
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'prawn/qrcode/version'

Gem::Specification.new do |spec|
  spec.name                      = 'prawn-qrcode'
  spec.version                   = Prawn::QRCode::VERSION
  spec.platform                  = Gem::Platform::RUBY
  spec.summary                   = 'Print QR Codes in PDF'
  spec.licenses                  = ['Apache License 2.0']
  spec.files = Dir.glob('{examples,lib,test}/**/**/*') +
               ['Rakefile', 'prawn-qrcode.gemspec']
  spec.require_path              = 'lib'
  spec.required_ruby_version     = '>= 2.2.0'
  spec.required_rubygems_version = '>= 1.3.6'

  spec.extra_rdoc_files          = %w[README.md LICENSE]
  spec.rdoc_options << '--title' << 'Prawn/QRCode Documentation' \
    '--main' << 'README.md' << '-q'
  spec.authors                   = ['Jens Hausherr']
  spec.email                     = ['jabbrwcky@gmail.com']
  spec.homepage                   = 'http://github.com/jabbrwcky/prawn-qrcode'

  spec.description                = <<END_DESC
  Prawn/QRCode simplifies the generation and rendering of QRCodes in Prawn PDF documents.
END_DESC

  spec.add_dependency('prawn', '>=1')
  spec.add_dependency('rqrcode', '>=1.0.0')

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'minitest', '~> 5.12', '>= 5.12.2'
  spec.add_development_dependency 'prawn-table', '~> 0.2.2'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 0.85.1'
end
