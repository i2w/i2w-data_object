# frozen_string_literal: true

require_relative 'data_object/version'
require_relative 'data_object/immutable'
require_relative 'data_object/mutable'

module I2w
  module DataObject
    class Error < RuntimeError; end

    class UnknownAttributeError < Error; end

    class MissingAttributeError < Error; end
  end
end
