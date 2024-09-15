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

qrcode = 'https://github.com/jabbrwcky/prawn-qrcode'

Prawn::Document.new(page_size: 'A4') do
  font 'Helvetica', style: :bold do
    text 'Sample autosized QR-Code (with stroked bounds). Size of dots : 3mm (huge)'
  end
  move_down 5.mm
  cpos = cursor
  font 'Courier', size: 8 do
    text_box "require 'prawn/measurement_extensions'\n\nprint_qr_code(qrcode, dot: 3.mm)", at: [320, cursor], height: 200, width: 220
  end
  print_qr_code(qrcode, dot: 3.mm)
  move_down 30

  font 'Helvetica', style: :bold do
    text 'Sample QR-Code (with and without stroked bounds) using dots with size: 1 mm (~2.8pt)'
  end

  move_down 10
  cpos = cursor
  print_qr_code(qrcode, dot: 1.mm)
  print_qr_code(qrcode, pos: [150, cpos], dot: 1.mm, stroke: false)
  font 'Courier', size: 8 do
    text_box "require 'prawn/measurement_extensions'\n\n" \
             "print_qr_code(qrcode, dot: 1.mm)\n" \
             'print_qr_code(qrcode, pos: [150,cpos], dot: 1.mm, stroke: false)', at: [320, cpos], height: 200, width: 220
  end

  move_down 30
  font 'Helvetica', style: :bold do
    text 'Higher ECC Levels (may) increase module size. '\
         'This QR Code uses ECC Level Q (ca. 30% of symbols can be recovered).'
  end
  move_down 10
  cpos = cursor
  print_qr_code(qrcode, dot: 1.mm, level: :q)
  font 'Courier', size: 8 do
    text_box "require 'prawn/measurement_extensions'\n\n" \
             'print_qr_code(qrcode, dot: 1.mm, level: :q)', at: [320, cpos], height: 200, width: 220
  end
  render_file('dotsize.pdf')
end
