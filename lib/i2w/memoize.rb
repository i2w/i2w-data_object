# frozen_string_literal: true

module I2w
  # Memoization which handles frozen objects, including, and extending modules with memoized methods
  module Memoize
    def self.extended(object) = Attach.call(object)

    def memoize(*method_names)
      method_names.each do |meth|
        visibility = (private_method_defined?(meth) && 'private') ||
                     (protected_method_defined?(meth) && 'protected') || 'public'

        alias_method "_unmemoized_#{meth}", meth
        remove_method meth

        module_eval <<~end_ruby, __FILE__, __LINE__
          #{visibility}                                           # protected
                                                                  #
          def #{meth}(*a, **kw)                                   # def foo(*a, **kw)
            _memoize_cache.fetch [:#{meth}, a, kw] do             #   _memoize_cache.fetch [:foo, a, kw] do
              _memoize_cache[_1] = _unmemoized_#{meth}(*a, **kw)  #     _memoize_cache[_1] = _unmemoized_foo(*a, **kw)
            end                                                   #   end
          end                                                     # end
        end_ruby
      end
    end

    module Attach #:nodoc:
      # setup class or singleton class for memoize, or prepend module hooks to ensure that happens
      def self.call(object)
        return object.include(ForSingleton) if object.singleton_class?
        return object.prepend(ForClass)     if object.instance_of?(Class)

        # object is a module: prepend this module, so that it extends or includes memoization setup
        object.singleton_class.prepend(Attach)
      end

      def included(object) = super.tap { Attach.call(object) }

      def extended(object) = super.tap { object.extend(ForSingleton) }
    end

    # Prepended to classes, to setup the memoization cache before anything else (such as becoming frozen)
    module ForClass #:nodoc:
      def initialize(...)
        @_memoize_cache = {}
        super
      end

      private

      attr_reader :_memoize_cache
    end

    # Singleton classes don't get initialized, so we set up a lazy reader for the memoization cache
    module ForSingleton #:nodoc:
      private

      def _memoize_cache = @_memoize_cache ||= {}
    end
  end
end
