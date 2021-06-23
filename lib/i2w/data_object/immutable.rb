# frozen_string_literal: true

require_relative 'attributes'

module I2w
  module DataObject
    # an immutable, frozen, DataObject
    class Immutable
      include Attributes
    end
  end
end
