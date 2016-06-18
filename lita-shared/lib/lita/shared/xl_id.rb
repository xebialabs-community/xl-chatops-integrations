module Lita
  module Shared
    class XlId
      attr_accessor :id

      def initialize(id)
        @id = id
      end

      def to_s
      	@id[/\/[^\/]+$/][/[^\/]+/]
      end

      def to_str
      	to_s
      end

      def full_id
        @id.to_s
      end
    end
  end
end
