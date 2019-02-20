module RubyMarks
  class Mark
    attr_accessor :coordinates, :group, :position, :line, :image_str, :distance_from_previous

    def initialize(params = {})
      params.each do |k, v|
        send("#{k}=", v) if respond_to?("#{k}=")
      end
    end

    def marked?
      intensity >= @group.recognizer.config.intensity_percentual if @image_str
    end

    def intensity
      colors = [] if @image_str

      @image_str.each do |y|
        y.each do |x|
          colors << x
        end
      end

      colors.count('.') * 100 / colors.size
    end

    def unmarked?
      !marked?
    end

    def value
      position = @group.marks[line].index(self) if @group

      values = @group.marks_options
      position && values[position]
    end
  end
end
