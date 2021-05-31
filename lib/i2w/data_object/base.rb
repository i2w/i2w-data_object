# frozen_string_literal: true

module I2w
  module DataObject
    # Base data object class, which allows attribute specification, and initialization with attributes.
    # Don't use this directly, use Mutable or Immutable
    class Base
      @attribute_names = []

      class << self
        attr_reader :attribute_names

        def attribute(name)
          @attribute_names << name
          attr_reader(name)
        end

        # create a data object from an object that can be double splatted
        #
        # Unlike .new this method:
        #   - ignores any unknown attributes
        #   - fills missing attributes with the result of calling the missing block, or nil
        def from(...)
          new(**to_attributes_hash(...))
        end

        # returns a hash of attributes with unknown removed, and missing filled
        def to_attributes_hash(object, &fill_missing)
          attributes = object.to_h.symbolize_keys.slice(*attribute_names)
          (attribute_names - attributes.keys).each { attributes[_1] = fill_missing&.call(_1) }
          attributes
        end

        private

        def inherited(subclass)
          super
          subclass.instance_variable_set(:@attribute_names, @attribute_names.dup)
        end
      end

      def initialize(**kwargs)
        unknown_attributes = kwargs.keys - attribute_names
        raise UnknownAttributeError, "Unknown attribute #{unknown_attributes}" if unknown_attributes.any?

        missing_attributes = attribute_names - kwargs.keys
        raise MissingAttributeError, "Missing attribute #{missing_attributes}" if missing_attributes.any?

        _set_attributes(kwargs)
      end

      def attributes = attribute_names.to_h { |attr| [attr, send(attr)] }

      def attribute_names = self.class.attribute_names

      private

      def _set_attributes(attrs)
        attrs.each { |name, value| instance_variable_set("@#{name}", value) }
      end
    end
  end
end
