#encoding: utf-8
module RubyMarks
  
  class Group
    attr_reader   :label, :document, :clocks_range

    attr_accessor :mark_width, :mark_height, :marks_options, :x_distance_from_clock, 
                  :distance_between_marks

    def initialize(label, document)
      @label = label
      @document = document
      @mark_width = @document.config.default_mark_width
      @mark_height = @document.config.default_mark_height
      @marks_options = @document.config.default_marks_options
      @distance_between_marks = @document.config.default_distance_between_marks
      @x_distance_from_clock = 0
      @clocks_range = 0..0
      yield self if block_given?
    end

    def clocks_range=(value)   
      value = value..value if value.is_a?(Fixnum)
      @clocks_range = value if value.is_a?(Range)
    end

    def belongs_to_clock?(clock)
      if @clocks_range.is_a?(Range)
        return @clocks_range.include? clock
      end
    end
  end

end