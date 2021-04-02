# frozen_string_literal: true

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
    end
  end
end

