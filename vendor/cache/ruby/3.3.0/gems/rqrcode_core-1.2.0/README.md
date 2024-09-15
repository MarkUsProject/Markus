![](https://github.com/whomwah/rqrcode_core/actions/workflows/ruby.yml/badge.svg)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

# RQRCodeCore

`rqrcode_core` is a library for encoding QR Codes in pure Ruby. It has a simple interface with all the standard qrcode options. It was originally adapted in 2008 from a Javascript library by [Kazuhiko Arase](https://github.com/kazuhikoarase).

Features:

* `rqrcode_core` is a Ruby only library. It requires no native libraries. Just Ruby!
* It is an encoding library. You can't decode QR Codes with it.
* The interface is simple and assumes you just want to encode a string into a QR Code, but also allows for encoding multiple segments.
* QR Code is trademarked by Denso Wave inc.

`rqrcode_core` is the basis of the popular `rqrcode` gem [https://github.com/whomwah/rqrcode]. This gem allows you to generate different renderings of your QR Code, including `png`, `svg` and `ansi`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rqrcode_core"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rqrcode_core

## Basic Usage

```ruby
$ require "rqrcode_core"
$ qr = RQRCodeCore::QRCode.new("https://kyan.com")
$ puts qr.to_s
```

Output:

```
xxxxxxx x  x x   x x  xx  xxxxxxx
x     x  xxx  xxxxxx xxx  x     x
x xxx x  xxxxx x       xx x xxx x
... etc
```

## Multiple Encoding Support

```ruby
$ require "rqrcode_core"
$ qr = RQRCodeCore::QRCode.new([{data: "byteencoded", mode: :byte_8bit}, {data: "A1" * 100, mode: :alphanumeric}, {data: "1" * 500, mode: :number}])
```

This will create a QR Code with byte encoded, alphanumeric and number segments. Any combination of encodings/segments will work provided it fits within size limits.

## Doing your own rendering

```ruby
require "rqrcode_core"

qr = RQRCodeCore::QRCode.new("https://kyan.com")
qr.rows.each do |row|
  row.each do |col|
    print col ? "#" : " "
  end

  print "\n"
end
```

### Options

The library expects a string or array (for multiple encodings) to be parsed in, other args are optional.

```
data - the string or array you wish to encode

size - the size (integer) of the QR Code (defaults to smallest size needed to encode the string)

max_size - the max_size (Integer) of the QR Code (default RQRCodeCore::QRUtil.max_size)

level  - the error correction level, can be:
  * Level :l 7%  of code can be restored
  * Level :m 15% of code can be restored
  * Level :q 25% of code can be restored
  * Level :h 30% of code can be restored (default :h)

mode - the mode of the QR Code (defaults to alphanumeric or byte_8bit, depending on the input data, only used when data is a string):
  * :number
  * :alphanumeric
  * :byte_8bit
  * :kanji
```

#### Example

```ruby
RQRCodeCore::QRCode.new("http://kyan.com", size: 1, level: :m, mode: :alphanumeric)
```

## Development

### Tests

You can run the test suite using:

```
$ ./bin/setup
$ rake
```

or try the project from the console with:

```
$ ./bin/console
```

### Linting

The project uses [standardrb](https://github.com/testdouble/standard) and can be run with:

```
$ ./bin/setup
$ rake standard # check
$ rake standard:fix # fix
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/whomwah/rqrcode_core.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
