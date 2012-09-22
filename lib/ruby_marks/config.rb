#encoding: utf-8
module RubyMarks
  
  class Config

    attr_accessor :clock_marks_scan_x
    
    def initialize
      @clock_marks_scan_x = @@clock_marks_scan_x
    end

  end

end