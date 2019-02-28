module RubyMarks
  class Mark
    def initialize(params = {})
      @coordinates            = params[:coordinates]
      @group                  = params[:group]
      @line                   = params[:line]
      @image_str              = params[:image_str]
    end

    def marked?(intensity_percentage)
      return unless image_str

      intensity >= intensity_percentage
    end

    def intensity
      return unless image_str

      nodes = image_str.flatten
      nodes.count('.') * 100 / nodes.size
    end

    def value
      position = group.marks[line].index(self) if group

      values = group.marks_options
      position && values[position]
    end

    private

    attr_reader :coordinates, :group, :line, :image_str
  end
end
