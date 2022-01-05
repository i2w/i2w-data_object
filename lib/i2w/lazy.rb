# frozen_string_literal: true

module I2w
  # simple protocol for deferring evaluation of values, used in DataObject::Extensions::Default, but can be used
  # anywhere
  class Lazy
    class << self
      # If the object is Lazy, resolve it given the context, otherwise return the object
      def resolve(object, context)
        object.is_a?(Lazy) ? object.resolve(context) : object
      end

      # Lazy.new(lazy, extra = nil) or
      # Lazy.new(extra = nil, &lazy)
      def new(*args, &block)
        args = [block, *args] if block
        super(*args)
      end
    end

    def initialize(lazy, extra = nil)
      @lazy = lazy
      @extra = extra
      freeze
    end

    def resolve(context)
      return context.send(@lazy) if @lazy.is_a?(Symbol)
      return @lazy unless @lazy.respond_to?(:call)

      callable = @lazy.respond_to?(:to_proc) ? @lazy : @lazy.method(:call)

      case callable.arity
      when 2 then callable.call(context, @extra)
      when 1 then callable.call(context)
      else        callable.call
      end
    end
  end
end
