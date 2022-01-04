# frozen_string_literal: true

require 'i2w/no_arg'

module I2w
  module DataObject
    module Extensions
      # extension that adds attribute defaults to your DataObject
      module Default
        def self.extended(into)
          raise ArgumentError, "extend #{self} before #{Type}" if into.singleton_class.ancestors.include?(Type)

          # only extend the attribute defining capability into an actual DataObject
          into.extend(AttributeMethods) if into.singleton_class.ancestors.include?(Attributes::ClassMethods)
        end

        protected

        def attribute(name, default: NoArg, **kwargs)
          super(name, **kwargs)
          _attributes[name][:default] = default unless default == NoArg
        end

        module AttributeMethods
          def new(**attributes) = super(**fill_missing_with_lazy_default(attributes))

          def from(hashy = {}) = super(fill_missing_with_lazy_default(**hashy))

          private

          def fill_missing_with_lazy_default(attributes)
            unresolved = attributes.dup
            (_attributes.keys - attributes.keys).each do
              if _attributes[_1].key?(:default)
                unresolved[_1] = Lazy.new(_attributes[_1][:default], attributes)
              end
            end
            unresolved
          end
        end
      end
    end
  end
end