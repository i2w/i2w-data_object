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

      memoize def foo(arg)
        @side_effects << [self, :foo, arg]
        "Foo: #{arg}"
      end
    end

    class ImmutableTest
      extend Memoize

      def initialize(side_effects = [])
        @side_effects = side_effects
        freeze
      end

      memoize def foo(arg)
        @side_effects << [self, :foo, arg]
        "Foo: #{arg}"
      end
    end

    class SubclassTest < Test
    end

    class ModuleTest
      module Foo
        extend Memoize

        memoize def foo(arg)
          @side_effects << [self, :foo, arg]
          "Foo: #{arg}"
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

        assert_equal [[obj, :foo, 1], [obj, :foo, 2], [obj, :foo, 3]], side_effects
      end
    end

    test 'memoization goes away after GC' do
      GC.start

      obj1 = Test.new
      obj2 = Test.new

      assert_equal 'Foo: 1', obj1.foo(1)
      assert_equal 'Foo: 2', obj2.foo(2)
      assert_equal 'Foo: 1', obj1.foo(1)

      assert_equal 2, Test.instance_variable_get(:@_memoize_cache).instance_eval { @cache }.length

      obj1 = nil
      GC.start

      assert_equal 'Foo: 2', obj2.foo(2)
      assert_equal 1,  Test.instance_variable_get(:@_memoize_cache).instance_eval { @cache }.length
    end

    test 'memoization of immutable objects' do
      GC.start
      obj = ImmutableTest.new

      assert_equal 'Foo: 1', obj.foo(1)
      assert_equal 'Foo: 1', obj.foo(1)

      assert_equal [{ [:foo, 1] => 'Foo: 1' }], ImmutableTest.instance_variable_get(:@_memoize_cache).instance_eval { @cache }.values
    end

    test 'memoization of module based methods' do
      GC.start
      obj = ModuleTest.new

      assert_equal 'Foo: 1', obj.foo(1)
      assert_equal 'Foo: 1', obj.foo(1)

      assert_equal [{ [:foo, 1] => 'Foo: 1' }], ModuleTest::Foo.instance_variable_get(:@_memoize_cache).instance_eval { @cache }.values
    end
  end
end
