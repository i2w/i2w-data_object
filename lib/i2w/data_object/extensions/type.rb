# frozen_string_literal: true

require 'active_model/type'

module I2w
  module DataObject
    module Extensions
      # extension to add activemodel:types to attributes, which are used to coerce incoming data
      module Type
        def self.extended(into)
          # only extend the attribute defining capability into an actual DataObject
          into.extend(AttributeClassMethods) if into.singleton_class.ancestors.include?(Attributes::ClassMethods)
        end

        protected

        def attribute(name, type_arg = nil, type: type_arg, **kwargs)
          super(name, **kwargs)
          _attributes[name][:type] = lookup_type(name, type)
        end

        def lookup_type(_name, type)
          return ObjectType if type.nil?

          type.respond_to?(:cast) ? type : ActiveModel::Type.lookup(type)
        end

        module AttributeClassMethods
          private

          def attributes_finalizer
            super.configure(define_writer: lambda do |mod, attr, meta|
              type = meta.fetch(:type)
              mod.define_method("#{attr}=") { instance_variable_set "@#{attr}", type.cast(Lazy.resolve(_1, self)) }
            end)
          end
        end

        # TODO: add an array type
        class ObjectType
          def self.cast(val) = val

          def self.type = :object
        end
      end
    end
  end
end