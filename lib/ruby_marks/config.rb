#encoding: utf-8
module RubyMarks
  
  class Config

    attr_accessor :clock_marks_scan_x, :intensity_percentual, :recognition_colors, :default_marks_options,
                  :default_distance_between_marks
    
    def initialize(document)
      @document = document
      @clock_marks_scan_x = @@clock_marks_scan_x
      @intensity_percentual = @@intensity_percentual
      @recognition_colors = @@recognition_colors
      @default_marks_options = @@default_marks_options
      @default_distance_between_marks = @@default_distance_between_marks
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