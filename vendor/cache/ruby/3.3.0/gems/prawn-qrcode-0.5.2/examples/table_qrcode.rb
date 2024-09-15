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
require 'rubygems'
require 'prawn'
require 'prawn/measurement_extensions'
require 'prawn/table'
require_relative '../lib/prawn/qrcode'
require_relative '../lib/prawn/qrcode/table'

# qrcode = 'https://github.com/jabbrwcky/prawn-qrcode'

Prawn::Document.new(page_size: 'A4') do
  font 'Helvetica', style: :bold do
    text 'QRCode in table'
  end
  move_down 5.mm
  cpos = cursor
  qr = make_qrcode_cell(content: 'https://github.com/jabbrwcky/prawn-qrcode', extent: 72)
  t = make_table([%w[URL QRCODE],
                  ['https://github.com/jabbrwcky/prawn-qrcode', qr]])
  t.draw
  move_down 20
  render_file('table.pdf')
end
