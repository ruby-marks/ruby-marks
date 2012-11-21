require "test_helper"

class RubyMarks::ImageUtilsTest < Test::Unit::TestCase

  def test_should_calculate_the_correct_width_of_given_coordinates
    assert_equal 11, RubyMarks::ImageUtils.calc_width(10, 20)
  end

  def test_should_calculate_the_correct_height_of_given_coordinates
    assert_equal 11, RubyMarks::ImageUtils.calc_height(10, 20)
  end

  def test_should_calculate_the_correct_middle_horizontal_of_given_coordinates
    assert_equal 15, RubyMarks::ImageUtils.calc_middle_horizontal(10, 11)
  end

  def test_should_calculate_the_correct_middle_vertical_of_given_coordinates
    assert_equal 15, RubyMarks::ImageUtils.calc_middle_vertical(10, 11)
  end

  def test_should_return_the_white_color_in_hexa_receiving_8bits
    color = RubyMarks::ImageUtils.to_hex(255, 255, 255)
    assert_equal "#FFFFFF", color
  end

  def test_should_return_the_white_color_in_hexa_receiving_16bits
    color = RubyMarks::ImageUtils.to_hex(65535, 65535, 65535)
    assert_equal "#FFFFFF", color
  end

end