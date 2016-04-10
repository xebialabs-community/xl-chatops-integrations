module Lita
  module Handlers
    # An XLD parameter
    class XldParameter
      attr_accessor :name, :value, :defaulted, :error

      def initialize(name = nil, value = nil)
        @name = name
        @value = value
        @defaulted = false
      end

    end
  end
end