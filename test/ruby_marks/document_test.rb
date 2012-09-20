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
    p @document.clock_list
    assert_equal 20, @document.clock_list.count

  end
end
 