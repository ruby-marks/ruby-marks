module RubyMarks
  class Watcher
    attr_reader :name, :recognizer

    def initialize(name, recognizer, &block)
      unless RubyMarks::AVAILABLE_WATCHERS.include?(name)
        raise ArgumentError, 'Invalid watcher name'
      end

      @name = name
      @recognizer = recognizer
      @action = block
    end

    def run(*args)
      @action&.call(@recognizer, *args)
    end
  end
end
