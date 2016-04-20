require 'multi_json'

require_relative './xld_parameter'
require_relative './xld_id'
require_relative './xlr_rest'
require_relative './bot_error'
require_relative './http_error'

#########
# 
# XL Release bot.
#

module Lita
  module Handlers
    class XlRelease < Handler

    	config :xlr_url
    	config :xlr_username
    	config :xlr_password
    	config :context_storage_timeout

		#########
      	# Events
      	on :loaded, :handler_loaded
      	on :release_status, :handle_release_status_update

		#########
      	# Routes
		route(/^releases$/i,
            :list_releases,
            command: false,
            help: { 'releases' => 'List all current releases' }
        )

		route(/^complete\s?([a-z0-9]{5})?$/i,
            :complete_task,
            command: false,
            help: { 'complete [task id]' => 'Complete a task' }
        )

		http.post "/activity", :receive_release_status

		##########################
      	# Event Handlers
		def handler_loaded(payload)
			log.debug('XlRelease handler loaded')
		end

		def handle_release_status_update(payload)
			log.debug('Received release status update')
			payload[:activity_id] =~ /\/(Release[0-9]+)\//
			releaseId = get_or_create_bot_id($1, false)
			if releaseId == nil
				print "Release not found for id #{$1}"
				return
			end

			type = payload[:activity_type]
			message = payload[:activity_message]
			taskId = get_or_create_bot_id(payload[:activity_task_id])

			if type == "TASK_OWNER_UPDATED"
				message =~ /^.*Task '([^']+)'.*to '?([^']+)'?$/
				taskName = $1
				owner = $2

				print "[#{releaseId}] Task '#{taskName}' owner changed to '#{owner}' [#{taskId}]"
			elsif type == "TASK_TASK_TEAM_UPDATED"
				message =~ /^.*Task '([^']+)'.*to '?([^']+)'?$/
				taskName = $1
				owner = $2

				print "[#{releaseId}] Task '#{taskName}' team changed to '#{owner}' [#{taskId}]"
			elsif type == "TASK_STARTED"
				message =~ /^.*Task '([^']+)'$/
				taskName = $1

				print "[#{releaseId}] Task '#{taskName}' started [#{taskId}]"
			end

			# if botId != nil
			# 	rooms = get_room_list_for_task_id(botId)
			# 	rooms.each { |room| robot.send_message(Source.new(room: room), "[#{botId}] #{payload[:task_status]}") }
			# end
		end

		#########
      	# XLR REST API
      	def xlr_rest_api(http)
			XlrRestApi.new(http, config.xlr_url, config.xlr_username, config.xlr_password)
      	end

		#########
      	# Helpers
		def get_or_create_bot_id(taskId, create = true)
			taskToBotKey = "taskId:" + taskId
			botId = redis.get(taskToBotKey)
			if botId == nil && create
				clash = true
				while clash
					botId = [*('a'..'z'),*('0'..'9')].shuffle[0,5].join
					botToTaskKey = "botId:" + botId
					taskToBotKey = "taskId:" + taskId
					clash = redis.get(botToTaskKey) != nil
					if (!clash)
						redis.set(botToTaskKey, taskId, { ex: config.context_storage_timeout })
						redis.set(taskToBotKey, botId, { ex: config.context_storage_timeout })
						log.debug(taskId + " -> " + botId + " (expire: #{config.context_storage_timeout})")
					end
				end
			end
			botId	
		end

		def determine_command_bot_id(message, botId)
			result = XldParameter.new("task")

			if botId == nil
				result.value = get_conversation_context(message, "currentXlrTaskBotId")
				result.defaulted = true
			else
				result.value = botId
			end

			if result.value == nil
				log.debug("unable to find task id")
				raise BotError, "Which task do you mean?"
			end

			result
		end

		def get_task_id(botId)
			botToTaskKey = "botId:" + botId
			taskId = redis.get(botToTaskKey)
			if taskId == nil
				raise BotError, "Sorry, don't know task " + botId
			end
			taskId	
		end

		def set_conversation_context(message, key, value)
		  	redis.set(message.user.id + ":" + message.room_object.id + ":" + key, value, { ex: config.context_storage_timeout })
		end

		def get_conversation_context(message, key)
		  	redis.get(message.user.id + ":" + message.room_object.id + ":" + key)
		end

		def clear_conversation_context(message, key)
		  	redis.del(message.user.id + ":" + message.room_object.id + ":" + key)
		end

		def print_release(botId, rel)
			"- " + rel["title"] + " (phase: " + rel["currentPhase"] + ", task: " + rel["currentTask"]["title"] + " [" + get_or_create_bot_id(rel["currentTask"]["id"]) + "]" + ")" + " [" + botId + "]"
		end

		def update_room_task_id(room, taskId)
		  	redis.sadd(taskId + ":rooms", room.id)
		end

		def get_room_list_for_task_id(taskId)
		  	redis.smembers(taskId + ":rooms")
		end

		def execute_with_error_reply(response, &block)
			begin
				block.call(response)
			rescue BotError => ex
				response.reply ex.to_s
			rescue => ex
				log.error("Error: " + ex.to_s)
				response.reply "Oops -- something went wrong. I'll have to get back to you later..."
				raise ex
			end
		end

		def register_new_task(response, taskId)
			newBotId = get_or_create_bot_id(taskId)
			set_conversation_context(response.message, "currentXlrTaskBotId", newBotId)
			update_room_task_id(response.message.room_object, newBotId)
			newBotId
		end

		def output_default_message(response, param1, param2 = nil, param3 = nil)
			defaultedMessage = ""
			[ param1, param2, param3].map { |x| 
				if x != nil && x.defaulted
					defaultedMessage = defaultedMessage + " " + x.name + " " + x.value
				end
			}

			if defaultedMessage != ""
				response.reply "(using" + defaultedMessage + ")"
			end
		end

		#########
      	# Chat route handlers
		def list_releases(response)
			execute_with_error_reply(response) {
				releases = xlr_rest_api(http).get_releases()

				response.reply "List of releases:"

				if releases["cis"] == nil
					response.reply("- none")
				else
					releases = releases["cis"]

					if releases.length == 0
						response.reply("- none")
					else
						for rel in releases do
							botId = get_or_create_bot_id(rel["id"])
							response.reply(print_release(botId, rel))
#							update_room_task_id(response.message.room_object, botId)
						end

						# message = response.message
						# clear_conversation_context(message, "currentXlrTaskBotId")
						# clear_conversation_context(message, "currentApplicationId")
						# clear_conversation_context(message, "currentVersionId")
						# clear_conversation_context(message, "currentEnvironmentId")

					end
				end
			}
		end

		def complete_task(response)
			execute_with_error_reply(response) {
				botId = determine_command_bot_id(response.message, response.match_data[1])

				output_default_message(response, botId)

			  	taskId = get_task_id(botId.value)

			  	response.reply "Completing task [#{botId.value}]"

			  	xlr_rest_api(http).complete_task(taskId)
			}
		end

		#########
      	# HTTP route handlers

		def receive_release_status(request, response)
		  body = MultiJson.load(request.body)
		  robot.trigger(:release_status, activity_id: body["id"], activity_type: body["type"], activity_message: body["message"], activity_task_id: body["taskId"])
		end

		Lita.register_handler(self)

    end
  end
end
