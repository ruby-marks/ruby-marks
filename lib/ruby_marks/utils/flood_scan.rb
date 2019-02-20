module RubyMarks
  class FloodScan
    attr_reader :image, :node, :width, :height, :queue, :vector_x, :vector_y,
                :steps

    def initialize(image)
      @image = image
    end

    def scan(node, width, height)
      initialize_data(node, width, height)
      process_queue until queue.empty?
      define_max_frequencies

      coordinates || {}
    end

    def coordinates
      return if vector_x.empty? || vector_y.empty?

      {
        x1: vector_x[0][0],
        y1: vector_y[0][0],
        x2: vector_x[0][1],
        y2: vector_y[0][1]
      }
    end

    private

    def process_queue
      shift_node
      node_processor.process(node) do |x, y|
        @vector_x[y] << x
        @vector_y[x] << y
        @steps += 1
      end
      queue.push(Magick::Point.new(x, y - 1)) if queue.empty? && steps < 100
    end

    def define_max_frequencies
      @vector_x = max_frequency_for(vector_x, width)
      @vector_y = max_frequency_for(vector_y, height)
    end

    def max_frequency_for(vector, measure)
      vector.find_mesure(measure, 5).max_frequency
    end

    def shift_node
      @node = queue.shift
    end

    def initialize_data(node, width, height)
      @steps = 0
      @queue = [].push(node)
      @node = node
      @width = width
      @height = height
      @vector_x = new_vector_hash
      @vector_y = new_vector_hash
    end

    def new_vector_hash
      Hash.new { |hash, key| hash[key] = [] }
    end

    def node_processor
      FloodScanProcessors::NodeProcessor.new(self)
    end
  end
end
