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
require_relative '../lib/prawn/qrcode'

qrcode = RQRCode::QRCode.new('https://github.com/jabbrwcky/prawn-qrcode', size: 5)

Prawn::Document.new(page_size: 'A4') do
  text 'Prawn QR Code sample 1: Predefined QR-Code'
  move_down 10
  text 'Sample predefined QR-Code (with stroked bounds) Size of QRCode dots: 1pt (1/72 in)'
  move_down 45
  render_qr_code(qrcode)
  move_down 10
  text 'Sample predefined QR-Code (without stroked bounds) Size of QRCode dots: 1pt (1/72 in)'
  move_down 45
  render_qr_code(qrcode, stroke: false)
  render_file('prepared.pdf')
end
