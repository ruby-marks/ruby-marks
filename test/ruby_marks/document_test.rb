require "test_helper"

class RubyMarks::DocumentTest < Test::Unit::TestCase
  
  def setup 
    @file = 'assets/sheet_demo1.png'
    @document = RubyMarks::Document.new(@file)
    @positions = {}
    @positions[:marked_position] = {x: 161, y: 794}
    @positions[:unmarked_position] = {x: 161, y: 994}
    @positions[:first_clock_position] = {x: 62, y: 794}
    @positions[:invalid_clock] = {x: 62, y: 1032}

    @document.configure do |config|
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
  end

  def test_should_initialize_a_document_with_a_valid_file
    assert_equal @file, @document.filename
  end

  def test_should_pass_the_configuration_to_document_config
    @document.configure do |config|
      config.clock_marks_scan_x = 30
    end
    assert_equal 30, @document.config.clock_marks_scan_x
  end

  def test_should_get_the_default_configuration_of_config_in_group
    @document.configure do |config|
      config.default_marks_options = %w{1 2 3}

      config.define_group :one
    end
    assert_equal %w{1 2 3}, @document.groups[:one].marks_options
  end

  def test_should_get_the_configuration_defined_in_group
    @document.configure do |config|
      config.default_marks_options = %w{1 2 3}      
      config.define_group :one do |group|
        group.marks_options = %w{X Y Z}
      end
    end
    assert_equal %w{X Y Z}, @document.groups[:one].marks_options
  end


  def test_should_return_a_file_with_a_position_flagged
    @document.current_position = @positions[:invalid_clock]
    flagged_document = @document.flag_position
    assert_equal Magick::Image, flagged_document.class

    # temp_filename = "temp_sheet_demo1.png"
    # File.delete(temp_filename) if File.exist?(temp_filename)
    # flagged_document.write(temp_filename)
  end

  def test_should_recognize_marked_position
    @document.current_position = @positions[:marked_position]
    assert @document.marked?(20, 20), "The position wasn't recognized as marked"    
  end

  def test_should_recognize_not_marked_position
    @document.current_position = @positions[:unmarked_position]
    assert @document.unmarked?(20, 20), "The position wasn't recognized as unmarked"    
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

  def test_should_scan_the_document_and_get_a_hash_of_marked_marks
    expected_hash = { 
      clock_1: {  
        group_first:  ['A'],
        group_second: ['A']
      },
      clock_2: {  
        group_first:  ['B'],
        group_second: ['B']
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
    assert_equal expected_hash, @document.scan 
  end
end
 