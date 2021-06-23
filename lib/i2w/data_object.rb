# frozen_string_literal: true

require_relative 'data_object/version'
require_relative 'data_object/attributes'

module I2w
  module DataObject
    class Error < RuntimeError; end

    class UnknownAttributeError < Error; end

    class MissingAttributeError < Error; end

    # an immutable, frozen, DataObject
    class Immutable
      include Attributes
    end

    # a DataObject that is mutable (has attr_writers, and uses defined setters on initialization)
    class Mutable
      include Attributes::Mutable
    end
  end
end
