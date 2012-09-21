#encoding: utf-8
module RubyMarks
  
  # Represents a scanned document
  class Document

    attr_reader :file

    attr_accessor :current_position, :clock_marks

    def initialize(file)
      @file = Magick::Image.read(file).first
      @current_position = {x: 0, y: 0}
      @clock_marks = [] 
    end

    def filename
      @file.filename
    end

    def move_to(x, y)
      @current_position = {x: @current_position[:x] + x, y: @current_position[:y] + y}
    end

    def marked?
      if self.current_position
        area_x = 8
        area_y = 8

        x_pos = current_position[:x]-area_x..current_position[:x]+area_x
        y_pos = current_position[:y]-area_y..current_position[:y]+area_y

        colors = []

        y_pos.each do |y|
          x_pos.each do |x|
            color = @file.pixel_color(x, y)
            color = RubyMarks::RGB.to_hex(color.red, color.green, color.blue)
            color = (color == "#000000") ? "." : " "
            colors << color
          end
        end
        black_intensity = colors.count(".") * 100 / colors.size
        return black_intensity >= 75 ? true : false
      end
    end

    def unmarked?
      !marked?
    end

    def flag_position
      file = @file.dup

      file.tap do |file|
        if current_position
          add_mark file
        end
      end
    end

    def flag_all_marks
      file = @file.dup

      file.tap do |file|
        position_before = @current_position
    
        scan_clock_marks unless clock_marks.any?
        groups = [87, 310, 535, 760, 985]
        marks = %w{A B C D E}
        clock_marks.each do |clock_mark|
          groups.each do |group|
            @current_position = {x: clock_mark.coordinates[:x2], y: clock_mark.vertical_middle_position}
            move_to(group, 0)
            marks.each do |mark|
              add_mark file
              move_to(25, 0)
            end
          end
        end

        @current_position = position_before
      end
    end

    def scan_clock_marks
      @clock_marks = []
      x = 62
      in_clock = false
      total_height = @file && @file.page.height || 0
      @clock_marks.tap do |clock_marks| 
        total_height.times do |y|
          clock = {}
          color = @file.pixel_color(x, y)
          color = RubyMarks::RGB.to_hex(color.red, color.green, color.blue)
          if !in_clock && color == "#000000"
            in_clock = true
            clock_marks << RubyMarks::ClockMark.new(document: self, position: {x: x, y: y+3})
          elsif in_clock && color != "#000000"
            in_clock = false
          end        
        end
      end
    end

    private
    def add_mark(file)
      flag = Magick::Draw.new
      p current_position
      file.annotate(flag, 0, 0, current_position[:x] - 12, current_position[:y] + 13, "+") do
        self.pointsize = 41
        self.stroke = '#000000'
        self.fill = '#C00000'
        self.font_weight = Magick::BoldWeight
      end
    end

  end

end