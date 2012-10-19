require "test_helper"

class RubyMarks::GroupTest < Test::Unit::TestCase

  def setup
    @file = 'assets/sheet_demo1.png'
    @recognizer = RubyMarks::Recognizer.new
    @recognizer.file = @file
    @group = RubyMarks::Group.new(:test, @recognizer)
  end

  def test_should_convert_fixnum_into_range_in_clocks_range
    @group.clocks_range = 1
    assert_equal 1..1, @group.clocks_range
  end

  def test_should_return_that_group_belongs_to_a_clock
    @group.clocks_range = 1..10
    assert @group.belongs_to_clock?(1), "Not recognized that group belongs to group 1"
  end

  def test_should_not_return_that_group_belongs_to_a_clock
    @group.clocks_range = 1..10
    assert !@group.belongs_to_clock?(11), "Recognized that group belongs to group 11"
  end
end
