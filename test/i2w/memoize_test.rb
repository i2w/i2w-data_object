# frozen_string_literal: true

require 'test_helper'

require 'i2w/memoize'

module I2w
  class MemoizeMethodVisibilityTest < ActiveSupport::TestCase
    class Test
      extend Memoize

      memoize def public_foo; end

      protected

      memoize def protected_foo; end

      private

      memoize def private_foo; end
    end

    test 'public methods remain public' do
      assert Test.public_instance_methods.include?(:public_foo)
    end

    test 'protected methods remain protected' do
      assert Test.protected_instance_methods.include?(:protected_foo)
    end

    test 'private methods remain private' do
      assert Test.private_instance_methods.include?(:private_foo)
    end
  end

  class MemoizeLintTest < ActiveSupport::TestCase
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

    class SingletonClassTest
      class << self
        extend Memoize

        attr_writer :side_effects

        memoize def foo(*args, **opts)
          @side_effects << [self, :foo, args, opts]
          "Foo: #{args.join(', ')}"
        end
      end
    end

    module SingletonModuleTest
      class << self
        extend Memoize

        attr_writer :side_effects

        memoize def foo(*args, **opts)
          @side_effects << [self, :foo, args, opts]
          "Foo: #{args.join(', ')}"
        end
      end
    end

    module ExtendSelfTest
      extend Memoize
      extend self

      attr_writer :side_effects

      memoize def foo(*args, **opts)
        @side_effects << [self, :foo, args, opts]
        "Foo: #{args.join(', ')}"
      end
    end

    class ExtendMemoizedModuleTest
      module MemoMod
        extend Memoize

        attr_writer :side_effects

        memoize def foo(*args, **opts)
          @side_effects << [self, :foo, args, opts]
          "Foo: #{args.join(', ')}"
        end
      end

      extend MemoMod
    end

    {
      class: [Test, SubclassTest, ImmutableTest, ModuleTest],
      singleton: [SingletonClassTest, SingletonModuleTest, ExtendSelfTest, ExtendMemoizedModuleTest]
    }.each do |type, classes|
      classes.each do |klass|
        test "#{type}: #{klass}: memoization works as expected" do
          side_effects = []

          obj = case type
                when :class
                  klass.new(side_effects)
                when :singleton
                  klass.side_effects = side_effects
                  klass
                end

          assert_equal 'Foo: 1', obj.foo(1)
          assert_equal 'Foo: 1', obj.foo(1)
          assert_equal 'Foo: 2', obj.foo(2)
          assert_equal 'Foo: 1', obj.foo(1)
          assert_equal 'Foo: 3', obj.foo(3)
          assert_equal 'Foo: 3', obj.foo(3)

          assert_equal [[obj, :foo, [1], {}],
                        [obj, :foo, [2], {}],
                        [obj, :foo, [3], {}]], side_effects

          obj.send(:_memoize_cache).clear

          assert_equal 'Foo: 1', obj.foo(1)
          assert_equal [[obj, :foo, [1], {}],
                        [obj, :foo, [2], {}],
                        [obj, :foo, [3], {}],
                        [obj, :foo, [1], {}]], side_effects

          assert_equal 'Foo: 1', obj.foo(1, busted: true)

          assert_equal [[obj, :foo, [1], {}],
                        [obj, :foo, [2], {}],
                        [obj, :foo, [3], {}],
                        [obj, :foo, [1], {}],
                        [obj, :foo, [1], { busted: true }]], side_effects
        end
      end
    end
  end
end