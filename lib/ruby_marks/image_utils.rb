#encoding: utf-8
module RubyMarks

  class ImageUtils

    def self.calc_width(x1, x2)
      x1 ||= 0
      x2 ||= 0

      x2 - x1 + 1
    end

    def self.calc_height(y1, y2)
      y1 ||= 0
      y2 ||= 0

      y2 - y1 + 1
    end

    def self.calc_middle_horizontal(x, width)
      x + width / 2
    end

    def self.calc_middle_vertical(y, height)
      y + height / 2
    end   
    

    def self.to_hex(red, green, blue)
      red = get_hex_from_color(red)
      green = get_hex_from_color(green)
      blue = get_hex_from_color(blue)
      "##{red}#{green}#{blue}".upcase
    end

    private 
    def self.get_hex_from_color(color)
      color = color.to_s(16)[0..1]
      color.size < 2 ? "0#{color}" : color
    end
 
  end

end
