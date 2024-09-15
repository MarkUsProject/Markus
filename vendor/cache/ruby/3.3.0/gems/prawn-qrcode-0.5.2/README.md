# Prawn/QRCode

A simple extension to generate and/or render QRCodes for Prawn PDFs

![TravisCI Build state](https://travis-ci.org/jabbrwcky/prawn-qrcode.svg?branch=master)
[![Gem Version](https://badge.fury.io/rb/prawn-qrcode.svg)](http://badge.fury.io/rb/prawn-qrcode)

Prawn/QRCode is a Prawn (>= 1.0.0) extension to simplify rendering of QR Codes*.

(*) QR Code is registered trademark of DENSO WAVE INCORPORATED.
    See http://www.denso-wave.com/qrcode/ for more information.

## Install

```bash
gem install prawn-qrcode
```

## Usage

```ruby
require 'prawn/qrcode'

qrcode_content = "http://github.com/jabbrwcky/prawn-qrcode"
qrcode = RQRCode::QRCode.new(qrcode_content, level: :h, size: 5)

# Render a prepared QRCode at he cursor position
# using a default module (e.g. dot) size of 1pt or 1/72 in
Prawn::Document::new do
  render_qr_code(qrcode)
  render_file("qr1.pdf")
end

# Render a code for raw content and a given total code size.
# Renders a QR Code at the cursor position measuring 1 in in width/height.
Prawn::Document::new do
  print_qr_code(qrcode_content, extent: 72)
  render_file("qr2.pdf")
end

# Render a code for raw content with a given dot size
Prawn::Document::new do
  # Renders a QR Code at he cursor position using a dot (module) size of 2.8/72 in (roughly 1 mm).
  render_qr_code(qrcode, dot: 2.8)
  render_file("qr3.pdf")
end
```

For a full list of examples, take a look in the `examples` folder.
