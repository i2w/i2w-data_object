# frozen_string_literal: true

module I2w
  module DataObject
    # extend this to gain class level #attribute method, and storage of attribute names
    module DefineAttributes
      private

      def _attributes = @_attributes ||= {}

      def attribute(name) = _attributes[name.to_sym] = {}
    end
  end
end
