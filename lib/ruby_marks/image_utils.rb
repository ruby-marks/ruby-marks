#encoding: utf-8
module RubyMarks

  class ImageUtils

    def self.calc_width(x1, x2)
      x2.to_i - x1.to_i + 1
    end

    def self.calc_height(y1, y2)
      y2.to_i - y1.to_i + 1
    end

    def self.calc_middle_horizontal(x, width)
      x.to_i + width.to_i / 2
    end

    def self.calc_middle_vertical(y, height)
      y.to_i + height.to_i / 2
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
