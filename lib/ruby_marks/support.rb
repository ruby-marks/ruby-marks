module RubyMarks
  module_function

  # rubocop:disable Style/EvalWithLocation
  # rubocop:disable Naming/HeredocDelimiterNaming
  def mattr_reader(*syms)
    syms.each do |sym|
      next if sym.is_a?(Hash)

      class_eval(<<-EOS, __FILE__, __LINE__)
        unless defined? @#{sym}
          @#{sym} = nil
        end

        def self.#{sym}
          @#{sym}
        end

        def #{sym}
          @#{sym}
        end
      EOS
    end
  end
  # rubocop:enable Style/EvalWithLocation
  # rubocop:enable Naming/HeredocDelimiterNaming

  # rubocop:disable Style/EvalWithLocation
  # rubocop:disable Naming/HeredocDelimiterNaming
  def mattr_writer(*syms)
    options = syms.last.is_a?(::Hash) ? pop : {}
    syms.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__)
        unless defined? @#{sym}
          @#{sym} = nil
        end

        def self.#{sym}=(obj)
          @#{sym} = obj
        end

        #{unless options[:instance_writer] == false
            "
        def #{sym}=(obj)
            @#{sym} = obj
        end
        "
          end}
      EOS
    end
  end
  # rubocop:enable Style/EvalWithLocation
  # rubocop:enable Naming/HeredocDelimiterNaming

  def mattr_accessor(*syms)
    mattr_reader(*syms)
    mattr_writer(*syms)
  end
end
