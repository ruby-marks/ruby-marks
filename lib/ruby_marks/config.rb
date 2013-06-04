#encoding: utf-8
module RubyMarks

  class Config

    attr_accessor :intensity_percentual, :edge_level, :default_marks_options, :threshold_level, 
                  :default_mark_width, :default_mark_height, :scan_timeout,
                  :default_mark_width_tolerance, :default_mark_height_tolerance,
                  :default_distance_between_marks, :default_expected_lines,
                  :default_block_width_tolerance, :default_block_height_tolerance, 
                  :scan_mode, :auto_ajust_block_width, :auto_ajust_block_height

    
    def initialize(recognizer)
      @recognizer = recognizer
      @threshold_level = RubyMarks.threshold_level
      @edge_level = RubyMarks.edge_level
      @scan_timeout = RubyMarks.scan_timeout

      @intensity_percentual = RubyMarks.intensity_percentual
      
      @default_block_width_tolerance  = RubyMarks.default_block_width_tolerance
      @default_block_height_tolerance = RubyMarks.default_block_height_tolerance

      @default_mark_width  = RubyMarks.default_mark_width
      @default_mark_height = RubyMarks.default_mark_height

      @default_mark_width_tolerance  = RubyMarks.default_mark_width_tolerance
      @default_mark_height_tolerance = RubyMarks.default_mark_height_tolerance
      
      @default_marks_options = RubyMarks.default_marks_options
      @default_distance_between_marks = RubyMarks.default_distance_between_marks
      @default_expected_lines = RubyMarks.default_expected_lines      
    end

    def calculated_threshold_level
      Magick::QuantumRange * (@threshold_level.to_f / 100)
    end

    def define_group(group_label, &block)
      group = RubyMarks::Group.new(group_label, @recognizer, &block)
      @recognizer.add_group(group)
    end

    def configure
      yield self if block_given?
    end

  end

end