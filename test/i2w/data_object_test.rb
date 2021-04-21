# frozen_string_literal: true

require 'test_helper'

module I2w
  class DataObjectTest < ActiveSupport::TestCase
    class ImmutablePoint < DataObject::Immutable
      attribute :x
      attribute :y
    end

    class MutablePoint < DataObject::Mutable
      attribute :x
      attribute :y
    end

    class Mutable3dPoint < MutablePoint
      attribute :z
    end

    test 'immutable data object' do
      point = ImmutablePoint.new(x: 3, y: 4)

      assert point.x == 3
      assert point.y == 4
      assert point.frozen?

      assert_equal({ **point }, { x: 3, y: 4 })

      refute point.respond_to?(:x=)
      refute point.respond_to?(:y=)
    end

    test 'mutable data object' do
      point = MutablePoint.new(x: 3, y: 4)
      assert point.x == 3
      assert point.y == 4
      refute point.frozen?

      assert_equal({ **point }, { x: 3, y: 4 })

      point.x = 5
      assert point.x == 5
    end

    test 'data object subclass' do
      point = Mutable3dPoint.new(x: 1, y: 2, z: 3)
      assert point.x == 1
      assert point.y == 2
      assert point.z == 3

      assert_equal({ **point }, { x: 1, y: 2, z: 3 })
    end

    test '#new with unknown attributes raises UnknownAttributeError' do
      assert_raise(DataObject::UnknownAttributeError) { MutablePoint.new(z: 8) }
    end

    test '#new with missing attributes raises MissingAttributeError' do
      assert_raise(DataObject::MissingAttributeError) { MutablePoint.new(x: 1) }
    end

    test '#from with unknown attributes ignores them' do
      point = MutablePoint.from(x: 1, y: 2, z: 3)
      assert point.x == 1
      assert point.y == 2
    end

    test '#from with missing attributes sets attributes to nil' do
      point = MutablePoint.from(x: 1)
      assert point.x == 1
      assert point.y.nil?
    end

    test "#from(...) { |attr| \"Missing \#{attr}\" } fills in the missing attribute" do
      point = MutablePoint.from(x: 1) { |attr| "Missing #{attr}" }
      assert point.x == 1
      assert point.y == 'Missing y'
    end

    test "#from(...) { 0 } fills in the missing attribute with 0" do
      point = MutablePoint.from(x: 1) { 0 }
      assert point.x == 1
      assert point.y == 0
    end

    test '#from with double splattable object works as expected' do
      other = Mutable3dPoint.new(x: 1, y: 2, z: 3)
      point = MutablePoint.from(other)
      assert point.x == 1
      assert point.y == 2
    end
  end
end
