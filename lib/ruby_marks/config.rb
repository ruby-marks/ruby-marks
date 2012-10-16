#encoding: utf-8
module RubyMarks

  class Config

    attr_accessor :clock_marks_scan_x, :intensity_percentual, :recognition_colors, 
                  :default_marks_options, :default_distance_between_marks, 
                  :clock_width, :clock_height, :threshold_level, :clock_mark_size_tolerance,
                  :default_mark_width, :default_mark_height
    
    def initialize(document)
      @document = document
      @threshold_level = RubyMarks.threshold_level
      
      @intensity_percentual = RubyMarks.intensity_percentual
      @recognition_colors   = RubyMarks.recognition_colors

      @clock_marks_scan_x = RubyMarks.clock_marks_scan_x
      @clock_width  = RubyMarks.clock_width
      @clock_height = RubyMarks.clock_height
      @clock_mark_size_tolerance = RubyMarks.clock_mark_size_tolerance
      
      @default_mark_width  = RubyMarks.default_mark_width
      @default_mark_height = RubyMarks.default_mark_height
      @default_marks_options = RubyMarks.default_marks_options
      @default_distance_between_marks = RubyMarks.default_distance_between_marks
    end

    def calculated_threshold_level
      Magick::QuantumRange * (@threshold_level.to_f / 100)
    end

    def width_with_down_tolerance
      @clock_width - @clock_mark_size_tolerance
    end

    def width_with_up_tolerance
      @clock_width + @clock_mark_size_tolerance
    end

    def height_with_down_tolerance
      @clock_height - @clock_mark_size_tolerance
    end

    def height_with_up_tolerance
      @clock_height + @clock_mark_size_tolerance
    end

    def width_tolerance_range
      width_with_down_tolerance..width_with_up_tolerance
    end

    def height_tolerance_range
      height_with_down_tolerance..height_with_up_tolerance
    end

    def define_group(group_label, &block)
      group = RubyMarks::Group.new(group_label, @document, &block)
      @document.add_group(group)
    end

    def configure
      yield self if block_given?
    end

  end

end