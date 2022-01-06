# frozen_string_literal: true

require_relative 'finalizer'

module I2w
  module DataObject
    module Attributes
      module ClassMethods #:nodoc:
        # create a data object from an object that can be double splatted, see #to_attributes_hash
        def from(...) = new(**to_attributes_hash(...))

        # returns a hash of attributes with unknown removed, and missing filled
        def to_attributes_hash(object, &fill_missing)
          attributes = object.to_h.symbolize_keys.slice(*attribute_names)
          (attribute_names - attributes.keys).each { attributes[_1] = fill_missing&.call(_1) }
          attributes
        end

        def attributes = @attributes ||= attributes_finalizer.call

        def attribute_names = attributes.keys

        private

        def attributes_finalizer = Finalizer.new(self)
      end
    end
  end
end