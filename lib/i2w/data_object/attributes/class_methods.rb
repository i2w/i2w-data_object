# frozen_string_literal: true

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

        def attributes = @attributes ||= finalize_attributes

        def attribute_names = attributes.keys

        private

        def finalize_attributes = ancestor_attributes.each { define_attribute_accessor _1, _2 }

        def define_attribute_accessor(attr, meta)
          define_reader(attr, meta)
          define_writer(attr, meta)
          define_writer_visibility(attr)
        end

        def define_reader(attr, _meta)
          attribute_methods.redefine_method(attr) { instance_variable_get "@#{attr}" }
        end

        def define_writer(attr, _meta)
          attribute_methods.redefine_method("#{attr}=") { |val| instance_variable_set "@#{attr}", val }
        end

        def define_writer_visibility(attr) = attribute_methods.send(:private, "#{attr}=")

        def attribute_methods
          module_eval 'module AttributeMethods; end', __FILE__, __LINE__
          include(self::AttributeMethods)
          self::AttributeMethods
        end

        def ancestor_attributes
          [self, *ancestors].map { _1.instance_variable_get :@_attributes }.reverse
                            .each_with_object({}) { |attrs, result| result.merge!(attrs) if attrs }
        end

        def inherited(subclass)
          finalize_attributes
          super
        end
      end
    end
  end
end