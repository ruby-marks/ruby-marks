require "test_helper"

class RubyMarks::DocumentTest < Test::Unit::TestCase
  def test_should_initialize_a_document_with_a_valid_file
  	file = 'assets/sheet_demo1.png'
  	document = RubyMarks::Document.new(file)
    assert_equal file, document.filename
  end
end
 