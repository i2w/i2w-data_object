# frozen_string_literal: true

require 'weakref'

module I2w
  # TODO: evaluate whether this is a bad idea (do some production testing), if it's OK, move into own gem
  #
  # enabes memoization, keeping references on the extended module or class, but with WeakRef keys,
  # which can be garbage collected. This makes it possible to memoize methods on frozen objects.
  #
  # inspired by https://github.com/iliabylich/memoized_on_frozen/blob/master/lib/memoized_on_frozen.rb
  module Memoize
    def self.extended(into)
      into.instance_variable_set(:@_memoize_cache, WeakRefCache.new)
      PrependSetWeakRefToClass.call(into)
    end

    def memoize(*method_names)
      memoize_cache = @_memoize_cache
      method_names.each do |meth|
        orig = instance_method(meth)
        remove_method(meth)
        define_method(meth) do |*args|
          cache = memoize_cache[@_weakref]
          cache.fetch([meth, *args]) { cache.store [meth, *args], orig.bind(self).call(*args) }
        end
      end
    end

    module PrependSetWeakRefToClass #:nodoc:
      # prepend SetWeakRef to class, or if a module, set a hook to ensure that eventually happens
      def self.call(into) = into.is_a?(Class) ? into.prepend(SetWeakRef) : into.singleton_class.prepend(Included)

      module Included #:nodoc:
        def included(into) = super.tap { PrependSetWeakRefToClass.call(into) }
      end
    end

    module SetWeakRef #:nodoc:
      def initialize(...)
        @_weakref = WeakRef.new(self)
        super
      end
    end

    # cache with weakref as keys, which are cleared on access if they are not alive.
    class WeakRefCache #:nodoc:
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
