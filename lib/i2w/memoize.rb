# frozen_string_literal: true

module I2w
  # Memoization which handles frozen objects, and including modules with memoized methods
  module Memoize
    def self.extended(object) = Attach.call(object)

    def memoize(*method_names)
      method_names.each do |method_name|
        orig_method = instance_method(method_name)

        remove_method(method_name)

        define_method(method_name) do |*args, **opts|
          key = [method_name, args, opts]
          _memoize_cache.fetch(key) { _memoize_cache[key] = orig_method.bind_call(self, *args, **opts) }
        end
      end
    end

    module Attach #:nodoc:
      # setup class or singleton class for memoize, or prepend module hooks to ensure that happens
      def self.call(object)
        return object.include(ForSingleton) if object.singleton_class?
        return object.prepend(ForClass)     if object.instance_of?(Class)

        # object is a module: prepend this, so that it extends or includes memoization setup
        object.singleton_class.prepend(Attach)
      end

      def included(object) = super.tap { Attach.call(object) }

      def extended(object) = super.tap { object.include(ForSingleton) }
    end

    module ForClass #:nodoc:
      def initialize(...)
        @_memoize_cache = {}
        super
      end

      private

      attr_reader :_memoize_cache
    end

    module ForSingleton #:nodoc:
      private

      def _memoize_cache = @_memoize_cache ||= {}
    end
  end
end
