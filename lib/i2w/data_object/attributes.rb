# frozen_string_literal: true

require_relative 'define_attributes'
require_relative 'attributes/class_methods'
require_relative 'attributes/instance_methods'

module I2w
  module DataObject
    # include this to define immutable attributes for your class or module
    module Attributes
      include InstanceMethods

      def self.included(into) = into.extend(ClassMethods, DefineAttributes)

      # attributes are initialized with private attribute writers, then freeze self
      def initialize(**attrs)
        assert_correct_attribute_names!(attrs.keys)
        attrs.each { send "#{_1}=", _2 }
        freeze
      end

      # include this to define mutable attributes for your class or module
      module Mutable
        include InstanceMethods

        def self.included(into) = into.extend(PublicAttributeWriter, ClassMethods, DefineAttributes)

        # attributes are initialized with public attribute writers
        def initialize(**attrs)
          assert_correct_attribute_names!(attrs.keys)
          attrs.each { public_send "#{_1}=", _2 }
        end

        module PublicAttributeWriter
          private

          def set_attribute_writer_visibility(attr) = attribute_methods.send(:public, "#{attr}=")
        end
      end
    end
  end
end
