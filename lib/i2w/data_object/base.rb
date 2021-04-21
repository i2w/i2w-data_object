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
        def from(object, &missing)
          attrs = object.to_hash.slice(*attribute_names)
          (attribute_names - attrs.keys).each { attrs[_1] = missing&.call(_1) }

          new(**attrs)
        end

        private

        def inherited(subclass)
          super
          subclass.instance_variable_set(:@attribute_names, @attribute_names.dup)
        end
      end

      def initialize(**kwargs)
        unknown_attributes = kwargs.keys - self.class.attribute_names
        raise UnknownAttributeError, "Unknown attribute #{unknown_attributes}" if unknown_attributes.any?

        missing_attributes = self.class.attribute_names - kwargs.keys
        raise MissingAttributeError, "Missing attribute #{missing_attributes}" if missing_attributes.any?

        kwargs.each { |name, value| instance_variable_set("@#{name}", value) }
      end

      def to_hash
        self.class.attribute_names.to_h { |attr| [attr, send(attr)] }
      end
    end
  end
end
