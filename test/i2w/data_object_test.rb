# frozen_string_literal: true

require 'test_helper'

module I2w
  class DataObjectTest < ActiveSupport::TestCase
    class ImmutablePoint < DataObject::Immutable
      attribute :x
      attribute :y
    end

    class ScaledImmutablePoint < ImmutablePoint
      def initialize(scale:, **kwargs)
        @scale = scale
        super(**kwargs)
      end

      def x = super * @scale

      # immutable objects can have memoized methods
      memoize def y = super * @scale
    end

    class MutablePoint < DataObject::Mutable
      attribute :x
      attribute :y
    end

    class FloatMutablePoint < MutablePoint
      def x=(val)
        @x = val.to_f
      end

      def y=(val)
        @y = val.to_f
      end
    end

    class Mutable3dPoint < MutablePoint
      attribute :z
    end

    module PointXY
      extend DataObject::DefineAttributes

      attribute :x
      attribute :y
    end

    module PointZ
      include DataObject::Attributes

      attribute :z
    end

    class ModularMutable3dPoint
      include PointXY
      include PointZ
      include DataObject::Attributes::Mutable
    end

    class ModularImmutable3dPoint
      include DataObject::Attributes::Immutable
      include PointXY
      include PointZ
    end

    test 'immutable data object' do
      point = ImmutablePoint.new(x: 3, y: 4)

      assert point.x == 3
      assert point.y == 4
      assert point.frozen?

      assert_equal({ x: 3, y: 4 }, point.attributes)

      refute point.respond_to?(:x=)
      refute point.respond_to?(:y=)
    end

    test 'mutable data object' do
      point = MutablePoint.new(x: 3, y: 4)
      assert point.x == 3
      assert point.y == 4
      refute point.frozen?

      assert_equal({ x: 3, y: 4 }, point.attributes)

      point.x = 5
      assert point.x == 5
    end

    test 'data object subclass' do
      point = Mutable3dPoint.new(x: 1, y: 2, z: 3)
      assert point.x == 1
      assert point.y == 2
      assert point.z == 3

      assert_equal({ x: 1, y: 2, z: 3 }, point.attributes)
    end

    test 'data object composed of mixins' do
      point = ModularMutable3dPoint.new(x: 1, y: 2, z: 3)
      assert point.x == 1
      assert point.y == 2
      assert point.z == 3

      point.z = 4

      assert_equal({ x: 1, y: 2, z: 4 }, point.attributes)

      point = ModularImmutable3dPoint.new(x: 1, y: 2, z: 3)

      refute point.respond_to?(:z=)
      assert point.frozen?
      assert_equal({ x: 1, y: 2, z: 3 }, point.attributes)
    end

    test 'data object with custom getters' do
      point = ScaledImmutablePoint.new(x: 2, y: 3, scale: 100)

      assert point.x == 200
      assert point.y == 300

      assert_equal({ x: 200, y: 300 }, point.attributes)
    end

    test 'data object with custom setters' do
      point = FloatMutablePoint.new(x: 1, y: BigDecimal('2'))

      assert_equal Float, point.x.class
      assert_equal Float, point.y.class

      assert_equal({ x: 1.0, y: 2.0 }, point.attributes)
    end

    test '#new with unknown attributes raises UnknownAttributeError' do
      assert_raise(DataObject::UnknownAttributeError) { MutablePoint.new(z: 8) }
    end

    test '#new with missing attributes raises MissingAttributeError' do
      assert_raise(DataObject::MissingAttributeError) { MutablePoint.new(x: 1) }
      assert_raise(DataObject::MissingAttributeError) { MutablePoint.new(x: 1, y: DataObject::MissingAttribute.instance) }
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

    test '#from(...) { 0 } fills in the missing attribute with 0' do
      point = MutablePoint.from(x: 1) { 0 }
      assert point.x == 1
      assert point.y == 0
    end

    test '#from with double splattable object works as expected' do
      point_3d = [[:x, 1], [:y, 2], [:z, 3]]
      point = MutablePoint.from(point_3d)
      assert point.x == 1
      assert point.y == 2
    end

    test '#to_attributes_hash(object, &fill_missing) returns a safe hash for .new' do
      actual = MutablePoint.to_attributes_hash([['x', 1], [:z, 4], [:zoopy, [1, 2, 3, 4]]]) { 0 }
      assert_equal({ x: 1, y: 0 }, actual)
    end

    test 'lazy attributes are resolved on setting' do
      actual = ImmutablePoint.new x: Lazy.new { 12 }, y: Lazy.new { _1.x * 2 }
      assert_equal({x: 12, y: 24}, actual.attributes)

      actual = ImmutablePoint.new x: Lazy.new(10), y: Lazy.new(2) { _1.x + _2 }
      assert_equal({x: 10, y: 12}, actual.attributes)

      actual = MutablePoint.new(x: 0, y: 0)
      actual.x = Lazy.new(-> { 1 })
      actual.y = Lazy.new(-> { _1.x + 1 })
      assert_equal({x: 1, y: 2}, actual.attributes)
    end
  end
end
