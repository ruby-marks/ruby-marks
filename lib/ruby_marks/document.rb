#encoding: utf-8
module RubyMarks
  
  # Represents a scanned document
  class Document

    attr_reader :file

    attr_accessor :current_position

    def initialize(file)
      @file = Magick::Image.read(file).first
      @current_position = {x: 0, y: 0}
    end

    def filename
      @file.filename
    end

    def marked?
      if self.current_position
        color = @file.pixel_color(current_position[:x], current_position[:y])
        color = RubyMarks::RGB.to_hex(color.red, color.green, color.blue)
        p color 
        return color == "#000000" ? true : false
      end
    end

    def flag_position
      flag = Magick::Draw.new
      file = @file.dup

      if self.current_position
        file.annotate(flag, 0, 0, current_position[:x] - 12, current_position[:y] + 15, "+") do
          #self.gravity = Magick::NorthGravity
          self.pointsize = 41
          self.stroke = '#000000'
          self.fill = '#C00000'
          self.font_weight = Magick::BoldWeight
        end
      end

      file
    end
  end

end