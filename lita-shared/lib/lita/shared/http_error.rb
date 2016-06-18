module Lita
  	module Shared
		class HttpError < RuntimeError
			attr :status

			def initialize(status)
				@status = status
			end
		end
	end
end
