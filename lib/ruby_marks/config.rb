#encoding: utf-8
module RubyMarks

  class Config

    attr_accessor :clock_marks_scan_x, :intensity_percentual, :recognition_colors, 
                  :default_marks_options, :default_distance_between_marks, 
                  :clock_width, :clock_height
    
    def initialize(document)
      @document = document
      @clock_marks_scan_x = RubyMarks.clock_marks_scan_x
      @intensity_percentual = RubyMarks.intensity_percentual
      @recognition_colors = RubyMarks.recognition_colors
      @default_marks_options = RubyMarks.default_marks_options
      @default_distance_between_marks = RubyMarks.default_distance_between_marks
      @clock_width = RubyMarks.clock_width
      @clock_height = RubyMarks.clock_height
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