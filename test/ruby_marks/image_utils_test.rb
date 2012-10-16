require "test_helper"

class RubyMarks::ImageUtilsTest < Test::Unit::TestCase
  
  def test_should_return_the_white_color_in_hexa_receiving_8bits
    color = RubyMarks::ImageUtils.to_hex(255, 255, 255)
    assert_equal "#FFFFFF", color
  end

  def test_should_return_the_white_color_in_hexa_receiving_16bits
    color = RubyMarks::ImageUtils.to_hex(65535, 65535, 65535)
    assert_equal "#FFFFFF", color
  end

end