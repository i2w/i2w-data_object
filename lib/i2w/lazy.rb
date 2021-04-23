# frozen_string_literal: true

require 'delegate'

module I2w
  class Lazy < Delegator
    def initialize(&block)
      super block
    end

    private

    def __getobj__
      __loadobj__ if @_unloaded_block
      @_loaded_object
    end

    def __setobj__(block)
      @_unloaded_block = block
    end

    def __loadobj__
      @_loaded_object = @_unloaded_block.call
      @_unloaded_block = nil
    end
  end
end

