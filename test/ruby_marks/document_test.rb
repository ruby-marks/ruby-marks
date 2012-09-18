require "test_helper"

class RubyMarks::DocumentTest < Test::Unit::TestCase
  
  def setup 
    @file = 'assets/sheet_demo1.png'
    @document = RubyMarks::Document.new(@file)
    @positions = {}
    @positions[:first_question] = {x: 161, y: 794}
  end

  def test_should_initialize_a_document_with_a_valid_file
    assert_equal @file, @document.filename
  end

  def test_should_return_a_file_with_a_position_flagged
    @document.current_position = @positions[:first_question]
    flagged_document = @document.flag_position
    assert_equal Magick::Image, flagged_document.class

    temp_filename = "temp_sheet_demo1.png"
    File.delete(temp_filename) if File.exist?(temp_filename)
    flagged_document.write(temp_filename)
  end

  def test_should_recognize_marked_position
    @document.current_position = @positions[:first_question]
    assert @document.marked?, "The position wasn't recognized as marked"    
  end
end
 