require File.dirname(__FILE__) + '/../test_helper'

class ExtraMarkTest < ActiveSupport::TestCase
  fixtures :results

  def test_create_extra_mark
    mark = ExtraMark.new({:result => results(:r1), :mark => 4, :description => "Bonus Mark"})
    assert mark.save
  end

end
