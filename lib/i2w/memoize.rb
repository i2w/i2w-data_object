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
    def self.extended(into)
      into.instance_variable_set(:@_memoize_cache, WeakRefCache.new)
      PrependSetWeakRefToClass.call(into)
    end

    def memoize(*method_names)
      weakref_cache = @_memoize_cache
      method_names.each do |method_name|
        original = instance_method(method_name)
        remove_method(method_name)
        define_method(method_name) do |*args|
          key = [method_name, *args]
          obj_cache = weakref_cache[_weakref]
          obj_cache.fetch(key) { obj_cache[key] = original.bind(self).call(*args) }
        end
      end
    end

    # we need to prepend SetWeakRef into the class that this is either extended with Memoize, or into any class
    # eventually including a module that is extended by Memoize
    module PrependSetWeakRefToClass
      def self.call(into)
        into.is_a?(Class) ? into.prepend(SetWeakRef) : into.singleton_class.prepend(self)
      end

      def included(into)
        PrependSetWeakRefToClass.call(into)
        super
      end
    end

    # set weak ref on initialization
    module SetWeakRef
      def initialize(...)
        @_weakref = WeakRef.new(self)
        super
      end

      private

      attr_reader :_weakref
    end

    # cache with weakref as keys, which are cleared on access if they are not alive.  Clearing only happens if the
    # GC has run since last access.
    class WeakRefCache
      # accepts same arguments as Hash.new, which is used to construct the cache
      def initialize
        @cleared_at = GC.count
        @cache = Hash.new { |cache, weakref| cache[weakref] = {} }
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
