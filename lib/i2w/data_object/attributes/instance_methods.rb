# frozen_string_literal: true

module I2w
  module DataObject
    module Attributes
      module InstanceMethods
        def attributes = attribute_names.to_h { [_1, send(_1)] }

        def attribute_names = self.class.attribute_names

        private

        def assert_correct_attribute_names!(names)
          unknown_attributes = names - attribute_names
          raise UnknownAttributeError, "Unknown attribute #{unknown_attributes}" if unknown_attributes.any?

          missing_attributes = attribute_names - names
          raise MissingAttributeError, "Missing attribute #{missing_attributes}" if missing_attributes.any?
        end
      end
    end
  end
end