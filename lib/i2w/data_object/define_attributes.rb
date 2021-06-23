# frozen_string_literal: true

module I2w
  module DataObject
    # extend this to gain class level #attribute method, and storage of attribute names
    module DefineAttributes
      def self.extended(into) = UpdateAttributeNames.call(into)

      attr_reader :attribute_names

      private

      def attribute(name)
        @attribute_names << name unless @attribute_names.include?(name)
        attr_reader(name) unless method_defined?(name)
        name
      end

      module UpdateAttributeNames #:nodoc:
        class << self
          def call(into, names = [])
            # ensure module/class has @attribute_names updated
            into.instance_eval { @attribute_names = [*@attribute_names, *names] }

            # ensure module/class attributes defined
            into.attribute_names.each { into.send(:attribute, _1) } if into.respond_to?(:attribute_names)

            # ensure module/class gets hook to update attribute names when included/inherited
            into.singleton_class.prepend(into.is_a?(Class) ? Inherited : Included)
          end
        end

        module Included #:nodoc:
          def included(into) = super.tap { UpdateAttributeNames.call(into, @attribute_names) }
        end

        module Inherited #:nodoc:
          def inherited(sub) = super.tap { sub.instance_variable_set :@attribute_names, @attribute_names.dup }
        end
      end
    end
  end
end
