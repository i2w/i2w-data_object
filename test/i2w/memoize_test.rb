# frozen_string_literal: true

require 'test_helper'

require 'i2w/memoize'

module I2w
  class MemoizeTest < ActiveSupport::TestCase
    class Test
      include Memoize

      def initialize(side_effects = [])
        @side_effects = side_effects
      end

      memoize def foo(arg)
        @side_effects << [self, :foo, arg]
        "Foo: #{arg}"
      end

      def bar(arg1, arg2)
        memoized :bar, arg1, arg2 do
          @side_effects << [self, :bar, arg1, arg2]
          "Bar: #{arg1}, #{arg2}"
        end
      end
    end

    class ImmutableTest
      include Memoize

      def initialize
        freeze
      end

      memoize def foo(arg)
        "Foo: #{arg}"
      end
    end

    test 'memoization works as expected' do
      side_effects = []

      obj = Test.new(side_effects)

      assert_equal 'Foo: 1', obj.foo(1)
      assert_equal 'Foo: 1', obj.foo(1)
      assert_equal 'Foo: 2', obj.foo(2)

      assert_equal 'Bar: 1, 1', obj.bar(1, 1)
      assert_equal 'Bar: 1, 2', obj.bar(1, 2)
      assert_equal 'Bar: 1, 2', obj.bar(1, 2)

      assert_equal [[obj, :foo, 1], [obj, :foo, 2], [obj, :bar, 1, 1], [obj, :bar, 1, 2]], side_effects
    end

    test 'memoization goes away after GC' do
      GC.start

      side_effects = []

      obj1 = Test.new
      obj2 = Test.new

      assert_equal 'Foo: 1', obj1.foo(1)
      assert_equal 'Foo: 2', obj2.foo(2)
      assert_equal 'Foo: 1', obj1.foo(1)

      assert_equal 2, Test.send(:memoized_cache).instance_eval { @cache }.length

      obj1 = nil
      GC.start

      assert_equal 'Foo: 2', obj2.foo(2)
      assert_equal 1, Test.send(:memoized_cache).instance_eval { @cache }.length
    end

    test 'memoization of immutable objects' do
      GC.start
      obj = ImmutableTest.new

      assert_equal 'Foo: 1', obj.foo(1)
      assert_equal 'Foo: 1', obj.foo(1)

      assert_equal [{ [:foo, 1] => 'Foo: 1' }], ImmutableTest.send(:memoized_cache).instance_eval { @cache }.values
    end
  end
end
