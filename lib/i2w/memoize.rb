# frozen_string_literal: true

module I2w
  # Simple memoization with handles frozen objects, and including modules with memoized methods
  module Memoize
    def self.extended(into)
      PrependMemoizeCache.call(into)
    end

    def memoize(*method_names)
      method_names.each do |method_name|
        orig_method = instance_method(method_name)

        remove_method(method_name)

        define_method(method_name) do |*args, **opts|
          key = [method_name, args, opts]
          @_memoize_cache.fetch(key) { @_memoize_cache[key] = orig_method.bind(self).call(*args, **opts) }
        end
      end
    end

    module PrependMemoizeCache #:nodoc:
      # prepend MemoizeCache to class, or if a module, set a hook to ensure that eventually happens
      def self.call(into) = into.is_a?(Class) ? into.prepend(MemoizeCache) : into.singleton_class.prepend(Included)

      module Included #:nodoc:
        def included(into) = super.tap { PrependMemoizeCache.call(into) }
      end
    end

    module MemoizeCache #:nodoc:
      def initialize(...)
        @_memoize_cache = {}
        super
      end

      private

      def _clear_memoization = @_memoize_cache.clear
    end
  end
end
