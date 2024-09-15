# Copyright 2011 - 2109 Jens Hausherr
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
require 'rubygems'
require 'prawn'
require 'prawn/measurement_extensions'
require_relative '../lib/prawn/qrcode'

data = 'https://github.com/jabbrwcky/prawn-qrcode'

Prawn::Document.new(page_size: 'A4') do
  text 'Sample autosized QR-Code (with stroked bounds) Size of QRCode : 1 in (72 pt)'
  print_qr_code(data, extent: 72)
  move_down 20

  text 'Sample autosized QR-Code (with and without stroked bounds) Size of QRCode : 2 in (144 pt)'
  cpos = cursor
  print_qr_code(data, extent: 144)
  print_qr_code(data, pos: [150, cpos], extent: 144, stroke: false)
  move_down 10

  text 'Sample autosized QR-Code (with stroked bounds) Size of QRCode :10 cm'
  print_qr_code(data, extent: 10.send(:cm), stroke: true, level: :q)
  move_down 10
  text "Quite huge, isn't it?"
  render_file('autosize.pdf')
end
