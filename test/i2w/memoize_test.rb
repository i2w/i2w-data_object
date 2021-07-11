# frozen_string_literal: true

require 'test_helper'

require 'i2w/memoize'

module I2w
  class MemoizeTest < ActiveSupport::TestCase
    class Test
      extend Memoize

      def initialize(side_effects = [])
        @side_effects = side_effects
      end

      memoize def foo(*args, **opts)
        @side_effects << [self, :foo, args, opts]
        "Foo: #{args.join(', ')}"
      end
    end

    class ImmutableTest
      extend Memoize

      def initialize(side_effects = [])
        @side_effects = side_effects
        freeze
      end

      memoize def foo(*args, **opts)
        @side_effects << [self, :foo, args, opts]
        "Foo: #{args.join(', ')}"
      end
    end

    class SubclassTest < Test
    end

    class ModuleTest
      module Foo
        extend Memoize

        memoize def foo(*args, **opts)
          @side_effects << [self, :foo, args, opts]
          "Foo: #{args.join(', ')}"
        end
      end

      module Bar
        include Foo
      end

      include Bar

      def initialize(side_effects = [])
        @side_effects = side_effects
      end
    end

    [Test, SubclassTest, ImmutableTest, ModuleTest].each do |klass|
      test "#{klass}: memoization works as expected" do
        side_effects = []

        obj = klass.new(side_effects)

        assert_equal 'Foo: 1', obj.foo(1)
        assert_equal 'Foo: 1', obj.foo(1)
        assert_equal 'Foo: 2', obj.foo(2)
        assert_equal 'Foo: 1', obj.foo(1)
        assert_equal 'Foo: 3', obj.foo(3)
        assert_equal 'Foo: 3', obj.foo(3)

        assert_equal [ [obj, :foo, [1], {}],
                       [obj, :foo, [2], {}],
                       [obj, :foo, [3], {}] ], side_effects

        obj.send(:_clear_memoization)

        assert_equal 'Foo: 1', obj.foo(1)
        assert_equal [ [obj, :foo, [1], {}],
                       [obj, :foo, [2], {}],
                       [obj, :foo, [3], {}],
                       [obj, :foo, [1], {}] ], side_effects

        assert_equal 'Foo: 1', obj.foo(1, busted: true)

        assert_equal [ [obj, :foo, [1], {}],
                       [obj, :foo, [2], {}],
                       [obj, :foo, [3], {}],
                       [obj, :foo, [1], {}],
                       [obj, :foo, [1], { busted: true }] ], side_effects
      end
    end
  end
end
