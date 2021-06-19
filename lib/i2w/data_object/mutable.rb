# frozen_string_literal: true

require_relative 'instance_methods'
require_relative 'class_methods'

module I2w
  module DataObject
    # a DataObject that is mutable (has attr_writers, and uses defined setters on initialization)
    class Mutable
      # Mutable Data Object behaviour
      module Mixin
        def self.included(klass)
          klass.include DataObject::InstanceMethods
          klass.extend ClassMethods, DataObject::ClassMethods
        end

        # class interface behaviour chnages
        module ClassMethods
          def attribute(name)
            super
            attr_writer(name)
          end
        end

        def initialize(**attrs)
          assert_correct_attributes!(attrs.keys)
          attrs.each { send "#{_1}=", _2 }
        end
      end

      include Mixin
    end
  end
end
