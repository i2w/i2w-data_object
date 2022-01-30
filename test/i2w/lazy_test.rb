# frozen_string_literal: true

module I2w
  class LazyTest < ActiveSupport::TestCase
    test "Lazy.resolve(<Lazy>, context) resovles Lazy with context" do
      lazy = Lazy.new { [:resolved, _1] }
      assert_equal [:resolved, :context], Lazy.resolve(lazy, :context)
    end

    test "Lazy.resolve(non-lazy, context) returns the non-lazy argument" do
      assert_equal :resolved, Lazy.resolve(:resolved, :context)
    end

    test "Lazy.to_lazy(<could be Lazy>, ...) wraps argument in Lazy unless it is already one" do
      lazy = Lazy.new { 3 }
      non_lazy = :count

      assert_equal lazy, Lazy.to_lazy(lazy)

      assert_equal 3, Lazy.to_lazy(lazy).resolve([1,2,3,4])
      assert_equal 4, Lazy.to_lazy(non_lazy).resolve([1,2,3,4])
    end

    test "Symbol resolved as method sent to context" do
      lazy = Lazy.new(:count)

      assert_equal 3, Lazy.resolve(lazy, [1,2,3])
    end

    test "non callable resolved as itself" do
      object = Object.new
      lazy = Lazy.new(object)

      assert_equal object, Lazy.resolve(lazy, :context)
    end

    test "arity 0 block is yielded" do
      result = :resolved
      lazy = Lazy.new { result }

      assert_equal :resolved, Lazy.resolve(lazy, :context)
    end

    test "arity 1 block is yielded with context" do
      result = :resolved
      lazy = Lazy.new { [result, _1] }

      assert_equal [:resolved, :context], Lazy.resolve(lazy, :context)
    end

    test "arity 2 block is yielded with context, and extra argument" do
      result = :resolved
      lazy = Lazy.new(:extra) { [result, _1, _2] }

      assert_equal [:resolved, :context, :extra], Lazy.resolve(lazy, :context)
    end

    test "lazy object with #call works the same as with blocks" do
      object_0 = Object.new.tap { _1.define_singleton_method(:call) { :resolved } }
      object_1 = Object.new.tap { _1.define_singleton_method(:call) { |c| [:resolved, c] } }
      object_2 = Object.new.tap { _1.define_singleton_method(:call) { |c, e| [:resolved, c, e] } }

      lazy_0 = Lazy.new(object_0)
      lazy_1 = Lazy.new(object_1)
      lazy_2 = Lazy.new(object_2, :extra)

      assert_equal :resolved,                     Lazy.resolve(lazy_0, :context)
      assert_equal [:resolved, :context],         Lazy.resolve(lazy_1, :context)
      assert_equal [:resolved, :context, :extra], Lazy.resolve(lazy_2, :context)
    end
  end
end