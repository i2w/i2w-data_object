# frozen_string_literal: true

module I2w
  module DataObject
    # class interface for DataObject
    module ClassMethods
      def self.extended(klass)
        klass.class_eval do
          def self.inherited(subclass)
            super
            subclass.instance_variable_set :@attribute_names, attribute_names.dup
          end
        end
      end

      def attribute_names = @attribute_names ||= []

      # declare an attribute for this data object
      def attribute(name)
        attribute_names << name
        attr_reader(name)
      end

      # create a data object from an object that can be double splatted
      #
      # Unlike .new this method:
      #   - ignores any unknown attributes
      #   - fills missing attributes with the result of calling the missing block, or nil
      def from(...) = new(**to_attributes_hash(...))

      # returns a hash of attributes with unknown removed, and missing filled
      def to_attributes_hash(object, &fill_missing)
        attributes = object.to_h.symbolize_keys.slice(*attribute_names)
        (attribute_names - attributes.keys).each { attributes[_1] = fill_missing&.call(_1) }
        attributes
      end
    end
  end
end
