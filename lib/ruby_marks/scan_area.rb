module RubyMarks

  class ScanArea
    attr_accessor :coordinates, :file

    def initialize(coordinates)
      @coordinates = coordinates
    end
  end

end