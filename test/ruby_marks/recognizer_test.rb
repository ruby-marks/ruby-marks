require "test_helper"

class RubyMarks::RecognizerTest < Test::Unit::TestCase
  
  def setup 
    @file = 'assets/sheet_demo1.png'
    @recognizer = RubyMarks::Recognizer.new
    @positions = {}
    @positions[:marked_position] = {x: 161, y: 794}
    @positions[:unmarked_position] = {x: 161, y: 994}

    @recognizer.configure do |config|  
      config.define_group :first  do |group|
        group.expected_coordinates = {x1: 145, y1: 780, x2: 270, y2: 1290}
      end

      config.define_group :second do |group| 
        group.expected_coordinates = {x1: 370, y1: 780, x2: 500, y2: 1290}
      end

      config.define_group :third  do |group| 
        group.expected_coordinates = {x1: 595, y1: 780, x2: 720, y2: 1290}
      end

      config.define_group :fourth do |group| 
        group.expected_coordinates = {x1: 820, y1: 780, x2: 950, y2: 1290}
      end

      config.define_group :fifth  do |group| 
        group.expected_coordinates = {x1: 1045, y1: 780, x2: 1170, y2: 1290}
      end

    end

    @recognizer.file = @file

    # file = @recognizer.file
    # temp_filename = "ttemp_sheet_demo1.png"
    # File.delete(temp_filename) if File.exist?(temp_filename)
    # file.write(temp_filename)

  end

  def test_should_initialize_a_recognizer_with_a_valid_file
    assert_equal @file, @recognizer.filename
  end

  def test_should_pass_the_configuration_to_recognizer_config
    @recognizer.configure do |config|
      config.threshold_level = 70
    end
    assert_equal 70, @recognizer.config.threshold_level
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
    flagged_document = @recognizer.flag_position @positions[:marked_position]
    assert_equal Magick::Image, flagged_document.class

    # temp_filename = "temp_sheet_demo1.png"
    # File.delete(temp_filename) if File.exist?(temp_filename)
    # flagged_document.write(temp_filename)
  end

  def test_should_recognize_marked_position
    @recognizer.detect_groups    
    group = @recognizer.groups[:first]
    line = group.marks[1]
    mark = line.first
    assert mark.marked?, "The position wasn't recognized as marked"    
  end

  def test_should_recognize_not_marked_position
    @recognizer.detect_groups
    group = @recognizer.groups[:first]
    line = group.marks[2]
    mark = line.first
    assert mark.unmarked?, "The position wasn't recognized as unmarked"    
  end


  def test_should_return_the_recognizer_with_all_marks_flagged
    flagged_recognizer = @recognizer.flag_all_marks
    assert_equal Magick::Image, flagged_recognizer.class

    temp_filename = "temp_sheet_demo2.png"
    File.delete(temp_filename) if File.exist?(temp_filename)
    flagged_recognizer.write(temp_filename)    
  end


  def test_should_scan_the_recognizer_and_get_a_hash_of_marked_marks
    expected_hash = { 
      first: {  
        1 => ['A'],
        2 => ['B'],
        3 => ['C'],
        4 => ['D'],
        5 => ['E']
      },
      second: {  
        1 => ['A'],
        2 => ['B'],
        3 => ['C'],
        4 => ['D'],
        5 => ['E']
      },
      third: {  
        2 => ['B'],
        3 => ['D'],
        4 => ['D']       
      }
    }
    result = @recognizer.scan
    result.each_pair do |group, lines|
      lines.delete_if { |line, value| value.empty? }
    end
    result.delete_if { |group, lines| lines.empty? }
    assert_equal expected_hash, result 
  end


  def test_should_make_watcher_raise_up
    @file = 'assets/sheet_demo1_invalid.png'
    @recognizer.file = @file 

    @recognizer.add_watcher :incorrect_group_watcher

    @recognizer.scan
    assert @recognizer.raised_watchers.include?(:incorrect_group_watcher)
  end


end
 