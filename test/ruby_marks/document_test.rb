require "test_helper"

class RubyMarks::DocumentTest < Test::Unit::TestCase
  
  def setup 
    @file = 'assets/sheet_demo1.png'
    @document = RubyMarks::Document.new(@file)
    @positions = {}
    @positions[:marked_position] = {x: 161, y: 794}
    @positions[:unmarked_position] = {x: 161, y: 994}
    @positions[:first_clock_position] = {x: 62, y: 794}

  end

  def test_should_initialize_a_document_with_a_valid_file
    assert_equal @file, @document.filename
  end

  def test_should_return_a_file_with_a_position_flagged
    @document.current_position = @positions[:first_clock_position]
    flagged_document = @document.flag_position
    assert_equal Magick::Image, flagged_document.class

    temp_filename = "temp_sheet_demo1.png"
    File.delete(temp_filename) if File.exist?(temp_filename)
    flagged_document.write(temp_filename)
  end

  def test_should_recognize_marked_position
    @document.current_position = @positions[:marked_position]
    assert @document.marked?, "The position wasn't recognized as marked"    
  end

  def test_should_recognize_not_marked_position
    @document.current_position = @positions[:unmarked_position]
    assert @document.unmarked?, "The position wasn't recognized as unmarked"    
  end

  def test_should_recognize_the_document_clock_marks
    @document.scan_clock_marks
    assert_equal 20, @document.clock_marks.count
  end

  def test_should_return_the_document_with_all_marks_flagged
    flagged_document = @document.flag_all_marks
    assert_equal Magick::Image, flagged_document.class

    temp_filename = "temp_sheet_demo2.png"
    File.delete(temp_filename) if File.exist?(temp_filename)
    flagged_document.write(temp_filename)    
  end

  def test_should_move_the_current_position_in_10_and_20_pixels
    @document.current_position = @positions[:marked_position]
    expected_position = {x: 171, y: 814}

    assert_equal expected_position, @document.move_to(10, 20)
  end

end
 