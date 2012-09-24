#encoding: utf-8
module RubyMarks
  
  class Group

    attr_reader :label, :document
    attr_accessor :marks_options, :x_distance_from_clock

    def initialize(label, document)
      @label = label
      @document = document
      @marks_options = @document.config.default_marks_options
      @x_distance_from_clock = 0
      yield self if block_given?
    end
  
  end

end