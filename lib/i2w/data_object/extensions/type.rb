# frozen_string_literal: true

require 'active_model/type'

module I2w
  module DataObject
    module Extensions
      # extension to add activemodel:types to attributes, which are used to coerce incoming data
      module Type
        def self.extended(into)
          # only extend the attribute defining capability into an actual DataObject
          into.extend(AttributeMethods) if into.singleton_class.ancestors.include?(Attributes::ClassMethods)
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

        module AttributeMethods
          private

          def define_attribute_writer(name, meta)
            type = meta.fetch(:type)
            attribute_methods.redefine_method("#{name}=") do |val|
              instance_variable_set :"@#{name}", type.cast(Lazy.resolve(val, self))
            end
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