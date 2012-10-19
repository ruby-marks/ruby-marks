#encoding: utf-8
module RubyMarks
  
  class ClockMark

    attr_accessor :recognizer, :coordinates

    def initialize(params={})
      params.each do |k, v|
        self.send("#{k}=", v) if self.respond_to?("#{k}=")
      end
    end

    def valid?

      return false if !self.recognizer.config.clock_width_tolerance_range.include?(self.width)   ||
                      !self.recognizer.config.clock_height_tolerance_range.include?(self.height)
      
      x_pos = coordinates[:x1]..coordinates[:x2]
      y_pos = coordinates[:y1]..coordinates[:y2]

      colors = []

      y_pos.each do |y|
        x_pos.each do |x|
          color = self.recognizer.file.pixel_color(x, y)
          color = RubyMarks::ImageUtils.to_hex(color.red, color.green, color.blue)
          color = recognizer.config.recognition_colors.include?(color) ? "." : " "
          colors << color
        end
      end

      intensity = colors.count(".") * 100 / colors.size
      return intensity >= 70 ? true : false
    end

    def invalid?
      !valid?
    end

    def width
      RubyMarks::ImageUtils.calc_width(@coordinates[:x1], @coordinates[:x2])
    end    

    def height
      RubyMarks::ImageUtils.calc_height(@coordinates[:y1], @coordinates[:y2])
    end

    def horizontal_middle_position
      RubyMarks::ImageUtils.calc_middle_horizontal(@coordinates[:x1], self.width)
    end

    def vertical_middle_position
      RubyMarks::ImageUtils.calc_middle_vertical(@coordinates[:y1], self.height)
    end

    def to_s
      self.coordinates
    end

  end 
end