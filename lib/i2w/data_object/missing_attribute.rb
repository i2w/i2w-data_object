# frozen_string_literal: true

module I2w
  module DataObject
    # Object that resolves to a MissingAttributeError
    # If you set an attribute as an instance of MissingAttribute, it will be as if the attribute was not passed
    class MissingAttribute
      class << self
        attr_reader :instance
      end

      def resolve(...) = raise(MissingAttributeError, 'missing attribute was resolved')

      @instance = new.freeze
    end
  end
end