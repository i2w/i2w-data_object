# frozen_string_literal: true

module I2w
  module DataObject
    # extend this to gain class level #attribute method, and storage of attribute names
    module DefineAttributes
      private

      def _attribute_names = @_attribute_names ||= []

      def attribute(name) = _attribute_names << name
    end
  end
end
