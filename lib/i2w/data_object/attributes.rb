# frozen_string_literal: true

require_relative 'define_attributes'
require_relative 'attributes/class_methods'
require_relative 'attributes/instance_methods'

module I2w
  module DataObject
    module Attributes
      include InstanceMethods

      def self.included(into) = into.extend(ClassMethods, DefineAttributes)

      # mutable attributes
      Mutable = Attributes

      # immutable attributes, this will freeze the instance on initialization
      module Immutable
        include InstanceMethods

        def initialize(...)
          super(...)
          freeze
        end

        def self.included(into) = into.extend(PrivateWriter, ClassMethods, DefineAttributes)

        module PrivateWriter #:nodoc:
          private

          def attributes_finalizer = super.configure(private_writer: true)
        end
      end
    end
  end
end
