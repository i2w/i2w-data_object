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
          def new(**attributes) = super(**fill_missing_with_unresolved(attributes))

          def from(hashy = {}) = super(fill_missing_with_unresolved(**hashy))

          private

          def fill_missing_with_unresolved(attributes)
            unresolved = attributes.dup
            (_attributes.keys - attributes.keys).each do
              if _attributes[_1].key?(:default)
                unresolved[_1] = Unresolved.new(_attributes[_1][:default], attributes)
              end
            end
            unresolved
          end

          def define_writer(attr, _meta)
            attribute_methods.redefine_method("#{attr}=") do |val|
              val = val.resolve(self) if val.is_a?(Unresolved)
              instance_variable_set "@#{attr}", val
            end
          end
        end

        class Unresolved
          def initialize(default, attributes)
            @default = default
            @attributes = attributes

            freeze
          end

          def resolve(instance)
            return instance.send(@default) if @default.is_a?(Symbol)
            return @default unless @default.respond_to?(:call)

            callable = @default.respond_to?(:to_proc) ? @default : @default.method(:call)
            case callable.arity
            when 2 then callable.call(instance, @attributes)
            when 1 then callable.call(instance)
            else        callable.call
            end
          end
        end
      end
    end
  end
end