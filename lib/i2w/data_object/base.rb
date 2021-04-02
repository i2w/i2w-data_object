# frozen_string_literal: true

module I2w
  module DataObject
    # Base data object class, which allows attribute specification, and initialization with attributes.
    # Don't use this directly, use Mutable or Immutable
    class Base
      @attribute_names = []

      class << self
        attr_reader :attribute_names

        def attribute(name)
          @attribute_names << name
          attr_reader(name)
        end

        private

        def inherited(subclass)
          super
          subclass.instance_variable_set(:@attribute_names, @attribute_names.dup)
        end
      end

      def initialize(**args)
        unknown_attributes = args.keys - self.class.attribute_names
        raise UnknownAttributeError, "Unknown attribute #{unknown_attributes}" if unknown_attributes.any?

        args.each { |name, value| instance_variable_set("@#{name}", value) }
      end
    end
  end
end

