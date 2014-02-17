module RubyMarks

  class Mark

    attr_accessor :coordinates, :group, :position, :line, :image_str, :distance_from_previous

    def initialize(params={})
      params.each do |k, v|
        self.send("#{k}=", v) if self.respond_to?("#{k}=")
      end
    end

    def marked?
      if @image_str
        return intensity >= @group.recognizer.config.intensity_percentual
      end
    end

    def intensity
      if @image_str
        colors = []

        @image_str.each do |y|
          y.each do |x|
            colors << x
          end
        end

        intensity = colors.count(".") * 100 / colors.size
      end
    end

    def unmarked?
      !marked?
    end

    def value 
      if @group
        position = @group.marks[line].index(self)
        
        values = @group.marks_options
        return position && values[position]
      end
    end
  end

end