# frozen_string_literal: true

require_relative 'instance_methods'
require_relative 'class_methods'

module I2w
  module DataObject
    # an immutable, frozen, DataObject
    class Immutable
      # Immutable behaviour
      module Mixin
        def self.included(klass)
          klass.include DataObject::InstanceMethods
          klass.extend DataObject::ClassMethods
        end

        def initialize(**attrs)
          assert_correct_attributes!(attrs.keys)
          attrs.each { instance_variable_set "@#{_1}", _2 }
          freeze
        end
      end

      include Mixin
    end
  end
end
