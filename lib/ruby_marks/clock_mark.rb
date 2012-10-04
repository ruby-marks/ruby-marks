#encoding: utf-8
module RubyMarks
  
  class ClockMark

    attr_accessor :document, :position, :coordinates

    def initialize(params={})
      params.each do |k, v|
        self.send("#{k}=", v) if self.respond_to?("#{k}=")
      end
      @coordinates = {x1: 0, x2: 0, y1: 0, y2: 0}
      self.calc_coordinates
    end

    def calc_coordinates
      @coordinates.tap do |coordinates|
        if self.document
          x = position[:x]
          y = position[:y]
          
          coordinates[:x1] = x
          loop do
            coordinates[:x1] -= 1
            color = self.document.file.pixel_color(coordinates[:x1], y)
            color = RubyMarks::RGB.to_hex(color.red, color.green, color.blue)

            break if !document.config.recognition_colors.include?(color) || coordinates[:x1] <= 0
          end

          coordinates[:x2] = x
          loop do
            coordinates[:x2] += 1
            color = self.document.file.pixel_color(coordinates[:x2], y)
            color = RubyMarks::RGB.to_hex(color.red, color.green, color.blue)

            break if !document.config.recognition_colors.include?(color) || coordinates[:x2] >= self.document.file.page.width
          end 

          coordinates[:y1] = y
          loop do
            coordinates[:y1] -= 1
            color = self.document.file.pixel_color(x, coordinates[:y1])
            color = RubyMarks::RGB.to_hex(color.red, color.green, color.blue)

            break if !document.config.recognition_colors.include?(color) || coordinates[:y1] <= 0
          end 

          coordinates[:y2] = y
          loop do
            coordinates[:y2] += 1
            color = self.document.file.pixel_color(x, coordinates[:y2])
            color = RubyMarks::RGB.to_hex(color.red, color.green, color.blue)

            break if !document.config.recognition_colors.include?(color) || coordinates[:y2] >= self.document.file.page.height
          end 
        end
      end
    end

    def valid?
      x_pos = coordinates[:x1]..coordinates[:x2]
      y_pos = coordinates[:y1]..coordinates[:y2]

      colors = []

      y_pos.each do |y|
        x_pos.each do |x|
          color = self.document.file.pixel_color(x, y)
          color = RubyMarks::RGB.to_hex(color.red, color.green, color.blue)
          color = document.config.recognition_colors.include?(color) ? "." : " "
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
      coordinates[:x2] - coordinates[:x1]
    end    

    def height
      coordinates[:y2] - coordinates[:y1]
    end

    def horizontal_middle_position
      coordinates[:x1] + self.width / 2
    end

    def vertical_middle_position
      coordinates[:y1] + self.height / 2
    end

    def to_s
      self.coordinates
    end
  end

end