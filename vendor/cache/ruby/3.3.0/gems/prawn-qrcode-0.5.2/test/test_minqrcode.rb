require 'minitest/autorun'
require 'prawn/qrcode'

class TestMinQRCode < Minitest::Test
  def test_dot_size_float
    qrcode = Prawn::QRCode.min_qrcode('foobar')
    assert(qrcode)
    dot = Prawn::QRCode.dotsize(qrcode, 72)
    assert_in_delta(2.5, dot, 0.05)
  end
end
