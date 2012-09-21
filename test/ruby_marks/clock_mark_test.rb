require "test_helper"

class RubyMarks::ClockMarkTest < Test::Unit::TestCase

  def setup 
    @file = 'assets/sheet_demo1.png'
    @document = RubyMarks::Document.new(@file)
    @positions = {}    
    @positions[:first_clock_position] = {x: 62, y: 794}
  end

  def test_should_get_clock_coordinates_by_a_given_position
    clock = RubyMarks::ClockMark.new(document: @document, position: @positions[:first_clock_position])
    expected_coordinates = {:x1=>48, :x2=>75, :y1=>790, :y2=>802}
    assert_equal expected_coordinates, clock.calc_coordinates
  end

end