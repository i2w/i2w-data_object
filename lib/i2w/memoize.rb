# frozen_string_literal: true

require 'weakref'

module I2w
  # TODO: move into own gem
  #
  # enabes memoization, keeping references on the class, but with WeakRef keys, so will be garbage collected
  # this makes it possible to memoize methods on frozen objects
  #
  # inspired by https://github.com/iliabylich/memoized_on_frozen/blob/master/lib/memoized_on_frozen.rb
  module Memoize
    def self.included(klass)
      klass.prepend SetWeakRef
      klass.extend ClassMethods
    end

    def memoized(*key, &block) = self.class.memoized(@_weakref, key, &block)

    # set weak ref on initialization
    module SetWeakRef
      def initialize(...)
        @_weakref = WeakRef.new(self)
        super
      end
    end

    class WeakRefCache
      def initialize(...)
        @cleared_at = GC.count
        @cache = Hash.new(...)
      end

      def [](weakref)
        clear_dead_weakrefs! unless GC.count == @cleared_at
        @cache[weakref]
      end

      private

      def clear_dead_weakrefs!
        @cache.select! { |k, _| k.weakref_alive? }
        @cleared_at = GC.count
      end
    end

    # class interface
    module ClassMethods
      def memoized_cache
        @memoized_cache ||= WeakRefCache.new { |m, key| m[key] = {} }
      end

      def memoized(weakref, key, &value)
        storage = memoized_cache[weakref]
        storage.fetch(key) { storage[key] = value.call }
      end

      private

      def memoize(*method_names)
        method_names.each do |method_name|
          original = instance_method(method_name)
          remove_method(method_name)
          define_method(method_name) { |*args| memoized(method_name, *args) { original.bind(self).call(*args) } }
        end
      end
    end
  end
end
