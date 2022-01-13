# frozen_string_literal: true

require_relative '../lazy'

module I2w
  module DataObject
    # Object that resolves to a MissingAttributeError
    # If you set an attribute as an instance of MissingAttribute, it will be as if the attribute was not passed
    class MissingAttribute
      # include this into your class to mark it as a missing attribute
      module Protocol; end

      include Protocol, Lazy::Protocol

      class << self
        attr_reader :instance

        def missing?(object) = object.is_a?(MissingAttribute::Protocol) ? true : false
      end

      def resolve(...) = raise(MissingAttributeError, 'missing attribute was resolved')

      @instance = new.freeze
    end
  end
end