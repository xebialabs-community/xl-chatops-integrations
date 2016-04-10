module Lita
  	module Handlers
		class HttpError < RuntimeError
			attr :status

			def initialize(status)
				@status = status
			end
		end
	end
end
