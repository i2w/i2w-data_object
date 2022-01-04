# frozen_string_literal: true

require 'test_helper'

module I2w
  module DataObject
    module Extensions
      class DefaultTest < ActiveSupport::TestCase
        class ImmutableDO < DataObject::Immutable
          extend DataObject::Extensions::Default

          attribute :foo, default: 'Foo'
          attribute :bar, default: -> { bar_default }
          attribute :foobar, default: -> { "#{_1.foo}#{_1.bar}" }
          attribute :baz, default: :default_baz
          attribute :all, default: -> { "foo:#{_2[:foo]},bar:#{_2[:bar]},baz:#{_2[:baz]}" }
          attribute :normal

          def self.bar_default = 'Bar'

          def default_baz = 'Baz'
        end

        test 'missing attributes have defaults provided when instantiated' do
          actual = ImmutableDO.new(normal: nil)
          assert_equal 'Foo', actual.foo
          assert_equal 'Bar', actual.bar
          assert_equal 'FooBar', actual.foobar
          assert_equal 'Baz', actual.baz
          assert_equal 'foo:,bar:,baz:', actual.all
        end

        test 'Immutable is frozen and attribute writers remain private' do
          actual = ImmutableDO.new(normal: nil)
          assert actual.frozen?
          assert actual.private_methods.include?(:foo=)
        end

        test 'Default with symbol is method sent on the data_object' do
          actual = ImmutableDO.new(normal: nil)
          assert_equal 'Baz', actual.baz
        end

        test 'Default with arity 0 is called with its original binding' do
          actual = ImmutableDO.new(normal: nil)
          assert_equal 'Bar', actual.bar
        end

        test 'Default with arity 1 is passed the data_object' do
          actual = ImmutableDO.new(normal: nil, foo: 'FOO')
          assert_equal 'FOOBar', actual.foobar
        end

        test 'Default with arity 2 is passed the data_object and the original attributes' do
          actual = ImmutableDO.new(normal: nil, bar: 'Bar')
          assert_equal 'foo:,bar:Bar,baz:', actual.all
        end

        test 'attributes without defaults still work the same' do
          assert_raises MissingAttributeError do
            ImmutableDO.new
          end
        end
      end
    end
  end
end