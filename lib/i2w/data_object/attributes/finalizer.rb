# frozen_string_literal: true

module I2w
  module DataObject
    module Attributes
      # collects the attributes from klass, and any ancestors, defines corresponding AttributeMethods and includes it
      class Finalizer #:nodoc:
        attr_reader :do_class, :define_writer

        def private_writer? = @private_writer

        def initialize(do_class, private_writer: false, define_writer: method(:default_define_writer))
          @do_class = do_class
          @private_writer = private_writer
          @define_writer = define_writer
        end

        def configure(private_writer: private_writer?, define_writer: self.define_writer)
          self.class.new(do_class, private_writer: private_writer, define_writer: define_writer)
        end

        # sets up our do_class with attribute reader/writers, and returns all the attributes with their meta info
        def call
          collect_attributes.tap do |attributes|
            do_class.const_set(:GeneratedAttributeMethods, define_attribute_methods_module(attributes))
            do_class.include(do_class::GeneratedAttributeMethods)
          end
        end

        private

        def collect_attributes
          [do_class, *do_class.ancestors].map { _1.instance_variable_get :@_attributes }.reverse
                                         .each_with_object({}) { |attrs, result| result.merge!(attrs) if attrs }
        end

        def define_attribute_methods_module(attributes)
          Module.new.tap { |mod| attributes.each { define_attribute(mod, _1, _2) } }
        end

        def define_attribute(mod, attr, meta)
          mod.attr_reader(attr)
          define_writer.call(mod, attr, meta)
          mod.send(:private, "#{attr}=") if private_writer?
        end

        def default_define_writer(mod, attr, _meta)
          mod.define_method("#{attr}=") { instance_variable_set "@#{attr}", Lazy.resolve(_1, self) }
        end
      end
    end
  end
end