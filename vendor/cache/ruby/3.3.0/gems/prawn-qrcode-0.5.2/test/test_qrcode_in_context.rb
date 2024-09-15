require 'minitest/autorun'
require 'prawn/qrcode'
require 'prawn/document'

class TestQrcodeInContext < Minitest::Test
  def test_render_with_margin
    context = Prawn::Document.new
    assert(context.print_qr_code('HELOWORLD', margin: 0))
  end
  def test_render_with_alignment
  	context = Prawn::Document.new
  	left = context.print_qr_code('HELLOWORLD', align: :left)
  	center = context.print_qr_code('HELLOWORLD', align: :center)
  	right = context.print_qr_code('HELLOWORLD', align: :right)
  	assert(left.anchor[0] < center.anchor[0])
  	assert(center.anchor[0] < right.anchor[0])
  end
end
