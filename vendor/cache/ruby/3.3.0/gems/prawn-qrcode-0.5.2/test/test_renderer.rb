require 'minitest/autorun'
require_relative '../lib/prawn/qrcode.rb'

class TestRenderer < Minitest::Test
  def setup
    @qrcode = Prawn::QRCode.min_qrcode('https://gituhb.com/jabbrwcky/prawn-qrcode')
  end

  def test_renderer_defaults
    r = Prawn::QRCode::Renderer.new(@qrcode)

    assert(r.stroke)
    assert_equal(Prawn::QRCode::DEFAULT_DOTSIZE, r.dot)
    assert_equal('000000', r.foreground_color)
    assert_equal('FFFFFF', r.background_color)
    assert_equal(4, r.margin)
    assert_equal(37.0, r.extent)
  end

  def test_renderer_extent
    r = Prawn::QRCode::Renderer.new(@qrcode, extent: 72)
    assert_in_delta(1.9, 0.05, r.extent)
  end

  def test_conflicting_dotsize_and_extent
    assert_raises(Prawn::QRCode::QRCodeError) { Prawn::QRCode::Renderer.new(@qrcode, dot: 3, extent: 72) }
  end
end
