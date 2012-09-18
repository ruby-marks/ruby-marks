#encoding: utf-8
module RubyMarks

  class RGB

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
