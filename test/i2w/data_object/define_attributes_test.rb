# frozen_string_literal: true

require 'test_helper'

require 'i2w/data_object/define_attributes'

module I2w
  module DataObject
    class DefineAttributesTest < ActiveSupport::TestCase
      module Foo
        extend DefineAttributes

        attribute :foo
      end

      module Bar
        extend DefineAttributes

        attribute :bar
      end

      module FooAndBar
        include Foo
        include Bar
      end

      class Test
        include FooAndBar
        extend DefineAttributes

        attribute :baz
      end

      test 'class that includes module with attributes' do
        assert_equal %i[foo bar baz], Test.attribute_names
      end
    end
  end
end
