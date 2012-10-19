require "test_helper"

class RubyMarks::RecognizerTest < Test::Unit::TestCase
  
  def setup 
    @file = 'assets/sheet_demo1.png'
    @recognizer = RubyMarks::Recognizer.new
    @positions = {}
    @positions[:marked_position] = {x: 161, y: 794}
    @positions[:unmarked_position] = {x: 161, y: 994}
    @positions[:first_clock_position] = {x: 62, y: 794}
    @positions[:invalid_clock] = {x: 62, y: 1032}

    @recognizer.configure do |config|
      config.define_group :first  do |group|
        group.clocks_range = 1..20 
        group.x_distance_from_clock = 87
      end

      config.define_group :second do |group| 
        group.clocks_range = 1..20         
        group.x_distance_from_clock = 310
      end

      config.define_group :third  do |group| 
        group.clocks_range = 1..20 
        group.x_distance_from_clock = 535
      end

      config.define_group :fourth do |group| 
        group.clocks_range = 1..20 
        group.x_distance_from_clock = 760
      end

      config.define_group :fifth  do |group| 
        group.clocks_range = 1..20 
        group.x_distance_from_clock = 985
      end
    end

    @recognizer.file = @file
  end

  def test_should_initialize_a_recognizer_with_a_valid_file
    assert_equal @file, @recognizer.filename
  end

  def test_should_pass_the_configuration_to_recognizer_config
    @recognizer.configure do |config|
      config.clock_marks_scan_x = 30
    end
    assert_equal 30, @recognizer.config.clock_marks_scan_x
  end

  def test_should_get_the_default_configuration_of_config_in_group
    @recognizer.configure do |config|
      config.default_marks_options = %w{1 2 3}

      config.define_group :one
    end
    assert_equal %w{1 2 3}, @recognizer.groups[:one].marks_options
  end

  def test_should_get_the_configuration_defined_in_group
    @recognizer.configure do |config|
      config.default_marks_options = %w{1 2 3}      
      config.define_group :one do |group|
        group.marks_options = %w{X Y Z}
      end
    end
    assert_equal %w{X Y Z}, @recognizer.groups[:one].marks_options
  end


  def test_should_return_a_file_with_a_position_flagged
    @recognizer.current_position = @positions[:invalid_clock]
    flagged_recognizer = @recognizer.flag_position
    assert_equal Magick::Image, flagged_recognizer.class

    # temp_filename = "temp_sheet_demo1.png"
    # File.delete(temp_filename) if File.exist?(temp_filename)
    # flagged_recognizer.write(temp_filename)
  end

  def test_should_recognize_marked_position
    @recognizer.current_position = @positions[:marked_position]
    assert @recognizer.marked?(20, 20), "The position wasn't recognized as marked"    
  end

  def test_should_recognize_not_marked_position
    @recognizer.current_position = @positions[:unmarked_position]
    assert @recognizer.unmarked?(20, 20), "The position wasn't recognized as unmarked"    
  end

  def test_should_recognize_the_recognizer_clock_marks
    @recognizer.scan_clock_marks
    assert_equal 20, @recognizer.clock_marks.count
  end

  def test_should_return_the_recognizer_with_all_marks_flagged
    flagged_recognizer = @recognizer.flag_all_marks
    assert_equal Magick::Image, flagged_recognizer.class

    temp_filename = "temp_sheet_demo2.png"
    File.delete(temp_filename) if File.exist?(temp_filename)
    flagged_recognizer.write(temp_filename)    
  end

  def test_should_move_the_current_position_in_10_and_20_pixels
    @recognizer.current_position = @positions[:marked_position]
    expected_position = {x: 171, y: 814}

    assert_equal expected_position, @recognizer.move_to(10, 20)
  end

  def test_should_scan_the_recognizer_and_get_a_hash_of_marked_marks
    expected_hash = { 
      clock_1: {  
        group_first:  ['A'],
        group_second: ['A']
      },
      clock_2: {  
        group_first:  ['B'],
        group_second: ['B'],
        group_third:  ['B']
      },
      clock_3: {  
        group_first:  ['C'],
        group_second: ['C'], 
        group_third:  ['D']            
      },
      clock_4: {  
        group_first:  ['D'],
        group_second: ['D'],
        group_third:  ['D']       
      },
      clock_5: {  
        group_first:  ['E'],
        group_second: ['E']
      }
    }
    assert_equal expected_hash, @recognizer.scan 
  end

end
 