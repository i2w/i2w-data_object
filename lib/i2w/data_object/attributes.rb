# frozen_string_literal: true

require_relative 'define_attributes'

module I2w
  module DataObject
    # include this to define immutable attributes for your class or module
    module Attributes
      module ClassMethods #:nodoc:
        def self.extended(into) = setup_attribute_attrs_module(into)

        def self.setup_attribute_attrs_module(klass) = klass.include(klass.const_set(:AttributeAttrs, Module.new))

        # create a data object from an object that can be double splatted, see #to_attributes_hash
        def from(...) = new(**to_attributes_hash(...))

        # returns a hash of attributes with unknown removed, and missing filled
        def to_attributes_hash(object, &fill_missing)
          attributes = object.to_h.symbolize_keys.slice(*attribute_names)
          (attribute_names - attributes.keys).each { attributes[_1] = fill_missing&.call(_1) }
          attributes
        end

        def attribute_names = @attribute_names ||= finalize_attribute_names

        private

        def finalize_attribute_names = ancestor_attribute_names.each { define_attribute_attr_method(_1) }

        def define_attribute_attr_method(name)
          self::AttributeAttrs.attr_reader(name) unless method_defined?(name)
        end

        def ancestor_attribute_names
          [self, *ancestors].map { _1.instance_variable_get :@_attribute_names }.compact.reverse.flatten.uniq
        end

        def inherited(subclass)
          finalize_attribute_names
          ClassMethods.setup_attribute_attrs_module(subclass)
          super
        end
      end

      module InstanceMethods #:nodoc:
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

      include InstanceMethods

      def self.included(into) = into.extend(ClassMethods, DefineAttributes)

      def initialize(**attrs)
        assert_correct_attribute_names!(attrs.keys)
        attrs.each { instance_variable_set "@#{_1}", _2 }
        freeze
      end

      # include this to define mutable attributes for your class or module
      module Mutable
        include InstanceMethods

        def self.included(into) = into.extend(AttributeWriters, ClassMethods, DefineAttributes)

        def initialize(**attrs)
          assert_correct_attribute_names!(attrs.keys)
          attrs.each { send "#{_1}=", _2 }
        end

        module AttributeWriters #:nodoc:
          private
          
          def define_attribute_attr_method(name)
            self::AttributeAttrs.attr_writer(name) unless method_defined?("#{name}=")
            super
          end
        end
      end
    end
  end
end
