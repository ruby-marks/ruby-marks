require "test_helper"

class RubyMarks::ClockMarkTest < Test::Unit::TestCase

  def setup 
    @file = 'assets/sheet_demo1.png'
    @document = RubyMarks::Document.new(@file)
    @positions = {}    
    @positions[:first_clock_position] = {x1: 49, x2: 74, y1: 790, y2: 801}
    @positions[:not_a_clock] = {x1: 62, x2:63, y1: 859, y2: 860}
  end

  def test_should_obtain_the_clock_mark_width
    clock = RubyMarks::ClockMark.new(document: @document, coordinates: @positions[:first_clock_position])
    assert_equal 26, clock.width
  end

  def test_should_obtain_the_clock_mark_height
    clock = RubyMarks::ClockMark.new(document: @document, coordinates: @positions[:first_clock_position])
    assert_equal 12, clock.height
  end

  def test_should_obtain_the_horizontal_middle_position
    clock = RubyMarks::ClockMark.new(document: @document, coordinates: @positions[:first_clock_position])
    assert_equal 62, clock.horizontal_middle_position
  end  

  def test_should_obtain_the_vertical_middle_position
    clock = RubyMarks::ClockMark.new(document: @document, coordinates: @positions[:first_clock_position])
    assert_equal 796, clock.vertical_middle_position
  end

  def test_should_recognize_a_valid_clock
    clock = RubyMarks::ClockMark.new(document: @document, coordinates: @positions[:first_clock_position])
    assert clock.valid?, "Not recognized a valid clock"
  end

  def test_should_recognize_a_invalid_clock
    clock = RubyMarks::ClockMark.new(document: @document, coordinates: @positions[:not_a_clock])
    assert clock.invalid?, "Recognized a invalid clock as a valid one"
  end

end