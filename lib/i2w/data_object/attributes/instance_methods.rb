# frozen_string_literal: true

module I2w
  module DataObject
    module Attributes
      module InstanceMethods
        def initialize(**attrs)
          assert_correct_attribute_names!(attrs.keys)
          attrs.each { send "#{_1}=", _2 }
        end

        def attributes = attribute_names.to_h { [_1, send(_1)] }

        def attribute_names = self.class.attribute_names

        private

        def assert_correct_attribute_names!(names)
          unknown = names - attribute_names
          raise UnknownAttributeError, "Unknown attribute #{unknown.join(', ')} for #{self.class}" if unknown.any?

          missing = attribute_names - names
          raise MissingAttributeError, "Missing attribute #{missing.join(', ')} for #{self.class}" if missing.any?
        end
      end
    end
  end
end