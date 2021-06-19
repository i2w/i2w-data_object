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

    private

    # return or cache the value for the given keys
    def memoized(*key, &value) = self.class.memoized(@_weakref, key, &value)

    # set weak ref on initialization
    module SetWeakRef
      def initialize(...)
        @_weakref = WeakRef.new(self)
        super
      end
    end

    # class interface
    module ClassMethods
      def memoized(weakref, key, &value)
        cache_for_weakref = memoize_cache[weakref]
        cache_for_weakref.fetch(key) { cache_for_weakref[key] = value.call }
      end

      private

      def memoize_cache = @memoize_cache ||= WeakRefCache.new { |m, key| m[key] = {} }

      # memoize the passed instance methods (does not handle methods that take blocks)
      def memoize(*method_names)
        method_names.each do |method_name|
          original = instance_method(method_name)
          remove_method(method_name)
          define_method(method_name) do |*args|
            memoized(method_name, *args) { original.bind(self).call(*args) }
          end
        end
      end
    end

    # cache with weakref as keys, which are cleared on access if they are not alive
    class WeakRefCache
      # accepts same arguments as Hash.new, which is used to construct the cache
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
  end
end
