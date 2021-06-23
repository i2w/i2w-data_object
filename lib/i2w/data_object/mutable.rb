# frozen_string_literal: true

require_relative 'attributes'

module I2w
  module DataObject
    # a DataObject that is mutable (has attr_writers, and uses defined setters on initialization)
    class Mutable
      include Attributes::Mutable
    end
  end
end
