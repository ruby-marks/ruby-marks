module RubyMarks

  class Watcher
    attr_reader :name, :recognizer

    def initialize(name, recognizer, &block)
      raise ArgumentError, "Invalid watcher name" unless RubyMarks::AVAILABLE_WATCHERS.include?(name)
      @name = name
      @recognizer = recognizer
      @action = block
    end

    def run(*args)
      @action.call(@recognizer, *args) if @action
    end
  end

end
