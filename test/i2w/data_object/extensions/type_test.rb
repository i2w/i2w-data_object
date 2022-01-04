# frozen_string_literal: true

require 'test_helper'

module I2w
  module DataObject
    module Extensions
      class TypeTest < ActiveSupport::TestCase
        class MutableDO < DataObject::Mutable
          extend DataObject::Extensions::Type

          attribute :amount,    :integer
          attribute :price,     :decimal
          attribute :starts_at, :date
          attribute :checked,   :boolean
          attribute :other
        end

        test 'typed attributes are coerced on creation' do
          actual = MutableDO.new(amount: "11", price: "14.23", starts_at: "2021/12/13", checked: "true", other: '1')
          assert_equal 11, actual.amount
          assert_equal BigDecimal('14.23'), actual.price
          assert_equal Date.new(2021, 12, 13), actual.starts_at
          assert_equal true, actual.checked
          assert_equal '1', actual.other
        end

        test 'typed attributes are not coerced from nil' do
          actual = MutableDO.from({})

          assert_nil actual.amount
          assert_nil actual.price
          assert_nil actual.starts_at
          assert_nil actual.checked
        end

        test 'typed attributes are coerced on set' do
          actual = MutableDO.from({})
          actual.amount = "  99 "
          assert_equal 99, actual.amount
          actual.checked = "1"
          assert_equal true, actual.checked
        end
      end

      class TypeWithDefaultTest < ActiveSupport::TestCase
        class MutableDO < DataObject::Mutable
          extend DataObject::Extensions::Default
          extend DataObject::Extensions::Type

          attribute :amount, :integer, default: '0'
          attribute :starts_at, :datetime, default: -> { Time.now }
        end

        test 'must extend Default before Type' do
          klass = Class.new
          klass.extend DataObject::Extensions::Type
          assert_raises ArgumentError do
            klass.extend DataObject::Extensions::Default
          end
        end

        test 'defaults are coerced' do
          actual = MutableDO.new

          assert_equal 0, actual.amount
          assert_in_delta Time.now, actual.starts_at, 1
        end
      end
    end
  end
end