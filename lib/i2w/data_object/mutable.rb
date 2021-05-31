# frozen_string_literal: true

require_relative 'base'

module I2w
  module DataObject
    # a DataObject that is mutable (has attr_writers)
    class Mutable < Base
      class << self
        def attribute(name)
          super
          attr_writer(name)
        end
      end

      private

      def _set_attributes(attrs)
        attrs.each { |name, value| send("#{name}=", value) }
      end
    end
  end
end
