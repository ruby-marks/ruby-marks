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
          
          stack = self.document.flood_scan(x, y)         
          x_elements = []
          y_elements = []
          stack.each do |k,v|
            stack[k].inject(x_elements, :<<)
            y_elements << k
          end

          x_elements.sort!.uniq!
          y_elements.sort!.uniq!

          loop do
            stack_modified = false

            x_elements.each do |col|
              element_count = 0
              y_elements.each do |row|
                element_count += 1 if stack[row].include?(col)
              end

              if element_count < self.document.config.clock_height - 2 
                x_elements.delete(col)
                stack_modified = true
              end
            end

            y_elements.each do |row|
              if stack[row].count < self.document.config.clock_width - 2
                y_elements.delete(row)
                stack_modified = true
              end
            end

            break unless stack_modified
          end

          x1 = x_elements.first || 0
          x2 = x_elements.last  || 0
          y1 = y_elements.first || 0
          y2 = y_elements.last  || 0 
        end

        @coordinates = {x1: x1, x2: x2, y1: y1, y2: y2}

        #p @coordinates
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
      coordinates[:x2] - coordinates[:x1] + 1
    end    

    def height
      coordinates[:y2] - coordinates[:y1] + 1
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