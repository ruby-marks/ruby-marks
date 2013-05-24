require "test_helper"

class RubyMarks::RecognizerGridTest < Test::Unit::TestCase
  
  def setup 
    @file = 'assets/sheet_demo_grid.png'
    @recognizer = RubyMarks::Recognizer.new
    @positions = {}
    @positions[:marked_position] = {x: 161, y: 794}
    @positions[:unmarked_position] = {x: 161, y: 994}

    @recognizer.configure do |config|  
    
      config.scan_mode = :grid
      config.default_expected_lines = 5
      config.intensity_percentual = 25
      
      config.define_group :um do |group|
        group.expected_coordinates = {x1: 100, y1: 200, x2: 250, y2: 350}
      end

      config.define_group :dois do |group|
        group.expected_coordinates = {x1: 350, y1: 200, x2: 500, y2: 350}
      end

      config.define_group :tres do |group|
        group.expected_coordinates = {x1: 570, y1: 200, x2: 720, y2: 350}
      end

      config.define_group :quatro do |group|
        group.expected_coordinates = {x1: 790, y1: 200, x2: 940, y2: 350}
      end

      config.define_group :cinco do |group|
        group.expected_coordinates = {x1: 1010, y1: 200, x2: 1160, y2: 350}
      end
    end

    @recognizer.file = @file

  end

  def test_should_return_the_recognizer_with_all_marks_flagged
    flagged_recognizer = @recognizer.flag_all_marks
    assert_equal Magick::Image, flagged_recognizer.class

    temp_filename = "sheet_demo_grid2.png"
    File.delete(temp_filename) if File.exist?(temp_filename)
    flagged_recognizer.write(temp_filename)    
  end

  def test_should_scan_the_recognizer_and_get_a_hash_of_marked_marks
    expected_hash = { 
      um: {  
        1 => ['B'],
        2 => ['B'],
        3 => ['A'],
        4 => ['B'],
        5 => ['A']
      },
      dois: {  
        1 => ['D'],
        2 => ['A'],
        3 => ['C'],
        4 => ['A'],
        5 => ['D']
      },
      tres: {  
        1 => ['B'],
        2 => ['A'],
        3 => ['A'],
        4 => ['A'],       
        5 => ['B']
      },
      quatro: {  
        1 => ['B'],
        2 => ['C'],
        3 => ['A'],
        4 => ['C'],       
        5 => ['E']
      },
      cinco: {  
        1 => ['A'],
        2 => ['B'],
        3 => ['A'],
        4 => ['A'],      
        5 => ['C']
      }
    }
    result = @recognizer.scan
    result.each_pair do |group, lines|
      lines.delete_if { |line, value| value.empty? }
    end
    result.delete_if { |group, lines| lines.empty? }
    assert_equal expected_hash, result 
  end
end