# frozen_string_literal: true

require_relative 'base'

module I2w
  module DataObject
    # an immutable, frozen, DataObject
    class Immutable < Base
      def initialize(**args)
        super
        freeze
      end
    end
  end
end
