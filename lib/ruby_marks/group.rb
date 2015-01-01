#encoding: utf-8
module RubyMarks

  class Group
    attr_reader   :label, :recognizer
    attr_accessor :mark_width, :mark_height, :marks_options, :coordinates, :expected_coordinates,
                  :mark_width_tolerance, :mark_height_tolerance, :marks, :distance_between_marks,
                  :block_width_tolerance, :block_height_tolerance, :expected_lines

    def initialize(label, recognizer)
      @label = label
      @recognizer = recognizer

      @block_width_tolerance  = @recognizer.config.default_block_width_tolerance
      @block_height_tolerance = @recognizer.config.default_block_height_tolerance

      @mark_width  = @recognizer.config.default_mark_width
      @mark_height = @recognizer.config.default_mark_height

      @mark_width_tolerance  = @recognizer.config.default_mark_width_tolerance
      @mark_height_tolerance = @recognizer.config.default_mark_height_tolerance

      @marks_options = @recognizer.config.default_marks_options
      @distance_between_marks = @recognizer.config.default_distance_between_marks

      @expected_lines = @recognizer.config.default_expected_lines
      @expected_coordinates = {}
      yield self if block_given?
    end

    def incorrect_expected_lines
      @expected_lines != marks.count
    end

    def mark_width_with_down_tolerance
      @mark_width - @mark_width_tolerance
    end

    def mark_width_with_up_tolerance
      @mark_width + @mark_width_tolerance
    end

    def mark_height_with_down_tolerance
      @mark_height - @mark_height_tolerance
    end

    def mark_height_with_up_tolerance
      @mark_height + @mark_height_tolerance
    end

    def mark_width_tolerance_range
      mark_width_with_down_tolerance..mark_width_with_up_tolerance
    end

    def mark_height_tolerance_range
      mark_height_with_down_tolerance..mark_height_with_up_tolerance
    end
  end
end
