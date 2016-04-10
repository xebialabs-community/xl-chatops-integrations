require_relative './xld_parameter'
require_relative './xld_id'
require_relative './xld_rest'
require_relative './bot_error'
require_relative './http_error'

#########
# 
# XL Deploy bot.
#

module Lita
  module Handlers
    class XlDeploy < Handler

    	config :xld_url
    	config :xld_username
    	config :xld_password
    	config :context_storage_timeout

		#########
      	# Events
      	on :loaded, :handler_loaded
      	on :task_status, :handle_task_status_update

		#########
      	# Routes
		route(/^deployments$/i,
            :list_deployments,
            command: false,
            help: { 'deployments' => 'List all current deployments' }
        )

		route(/^environments$/i,
            :list_environments,
            command: false,
            help: { 'environments' => 'List all environments' }
        )

		route(/^applications$/i,
            :list_applications,
            command: false,
            help: { 'applications' => 'List all applications' }
        )

		route(/^versions(\s([a-z][^\s]+))?$/i,
            :list_versions,
            command: false,
            help: { 'versions' => 'List all application versions' }
        )

		route(/^deploy(\s([a-z][^\s]+))?(\s([0-9][^\s]+))?(\sto\s([a-z]+))?$/i,
            :start_deployment,
            command: false,
            help: { 'deploy [application] [version] to [environment]' => 'Start a new deployment' }
        )

		route(/^rollback\s?([a-z0-9]{5})?$/i,
            :rollback_task,
            command: false,
            help: { 'rollback [task id]' => 'Rollback a task' }
        )

		route(/^start\s?([a-z0-9]{5})?$/i,
            :start_task,
            command: false,
            help: { 'start [task id]' => 'Start a task' }
        )

		route(/^abort\s?([a-z0-9]{5})?$/i,
            :abort_task,
            command: false,
            help: { 'abort [task id]' => 'Abort a task' }
        )

		route(/^cancel\s?([a-z0-9]{5})?$/i,
            :cancel_task,
            command: false,
            help: { 'cancel [task id]' => 'Cancel a task' }
        )

		route(/^archive\s?([a-z0-9]{5})?$/i,
            :archive_task,
            command: false,
            help: { 'archive [task id]' => 'Archive a task' }
        )

		route(/^log\s?([a-z0-9]{5})?$/i,
            :log_task,
            command: false,
            help: { 'log [task id]' => 'Show a task log' }
        )

		route(/^desc\s?([a-z0-9]{5})?$/i,
            :describe_task,
            command: false,
            help: { 'desc [task id]' => 'Describe a task' }
        )

		http.post "/task/:id/:status", :receive_task_status

		##########################
      	# Event Handlers
		def handler_loaded(payload)
			log.debug('XlDeploy handler loaded')
		end

		def handle_task_status_update(payload)
			log.debug('Received task status update')
			taskStatus = payload[:task_status]

			return if 
				taskStatus == "CANCELLING" ||
				taskStatus == "QUEUED"

			taskId = payload[:task_id]
			botId = get_or_create_bot_id(taskId, false)
			if botId != nil
				rooms = get_room_list_for_task_id(botId)
				rooms.each { |room| robot.send_message(Source.new(room: room), "[#{botId}] #{payload[:task_status]}") }
			end
		end

		#########
      	# XLD REST API
      	def xld_rest_api(http)
			XldRestApi.new(http, config.xld_url, config.xld_username, config.xld_password)
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
				result.value = get_conversation_context(message, "currentTaskBotId")
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

		def print_task(botId, task)
			"- [" + task["@state"] + "] " + task["metadata"]["application"]["$"] + "/" + task["metadata"]["version"]["$"] + " to " + task["metadata"]["environment"]["$"] + " [" + botId + "] "
		end

		def update_room_task_id(room, taskId)
		  	redis.sadd(taskId + ":rooms", room.id)
		end

		def get_room_list_for_task_id(taskId)
		  	redis.smembers(taskId + ":rooms")
		end

		def determine_initial_or_update(http, appId, envId)
			return "update" if xld_rest_api(http).deployment_exists(appId, envId)
			return "initial"
		end

		def determine_application(message, http, appId)
			result = XldParameter.new("application")
			if appId == nil
				result.value = get_conversation_context(message, "currentApplicationId")
				result.defaulted = true
				log.debug("defaulted application to context")

				if result.value == nil
					log.debug("unable to find application")
					result.error = "Which application are you looking for?"
				end

			else
				log.debug("searching XLD for application " + appId)
				begin

					rest_result = xld_rest_api(http).find_application(appId)
		            ci_list = rest_result["list"]
		            if ci_list["ci"] == nil
	        			result.error = "Unable to find application " + appId
	        		else
			            cis = ci_list["ci"]
	          			if cis.is_a? Array
	            			ids = cis.map { |x| x["@ref"]}.join(", ")
	            			result.error = "Which application do you mean? (candidates: " + ids + ")"
	          			else
	            			result.value = XldId.new(cis["@ref"])
	          			end
	          		end

				rescue RuntimeError => ex
					result.error = ex.to_s
				end
			end

			result
		end

		def determine_version(message, http, applicationId, versionId)
			result = XldParameter.new("version")
			if versionId == nil
				result.defaulted = true
				result.value = get_conversation_context(message, "currentVersionId")

				if result.value == nil
					result.error = "Which version of " + applicationId + " are you looking for?"
				end

			else
				begin
					rest_result = xld_rest_api(http).find_version(applicationId.full_id, versionId)
		            ci_list = rest_result["list"]
		            if ci_list["ci"] == nil
	        			result.error = "Unable to find version " + versionId
	        		else
			            cis = ci_list["ci"]
	          			if cis.is_a? Array
	            			ids = cis.map { |x| x["@ref"]}.join(", ")
	            			result.error = "Which version do you mean? (candidates: " + ids + ")"
	          			else
	            			result.value = XldId.new(cis["@ref"])
	          			end
	          		end
				rescue RuntimeError => ex
					result.error = ex.to_s
				end
			end

			result
		end

		def determine_environment(message, http, envId)
			result = XldParameter.new("env")
			if envId == nil
				result.value = get_conversation_context(message, "currentEnvironmentId")
				result.defaulted = true

				if result.value == nil
					result.error = "Which environment are you looking for?"
				end

			else
				begin
					rest_result = xld_rest_api(http).find_environment(envId)
		            ci_list = rest_result["list"]
		            if ci_list["ci"] == nil
	        			result.error = "Unable to find environment " + envId
	        		else
			            cis = ci_list["ci"]
	          			if cis.is_a? Array
	            			ids = cis.map { |x| x["@ref"]}.join(", ")
	            			result.error = "Which environment do you mean? (candidates: " + ids + ")"
	          			else
	            			result.value = XldId.new(cis["@ref"])
	          			end
	          		end
				rescue RuntimeError => ex
					result.error = ex.to_s
				end
			end

			result
		end

		def show_log_tail(response, http, botId)
			taskId = get_task_id(botId)

			log = xld_rest_api(http).get_current_step_log(taskId)
			loglines = log.split("\n")

			# Print last 20 lines
			if loglines.length > 20
				loglines = loglines.slice(loglines.length - 20)
			end
			loglines.each { |x| response.reply botId + "> " + x }
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
			set_conversation_context(response.message, "currentTaskBotId", newBotId)
			update_room_task_id(response.message.room_object, newBotId)
			newBotId
		end

		#########
      	# Chat route handlers
		def list_deployments(response)
			execute_with_error_reply(response) {
				tasks = xld_rest_api(http).do_get_tasks()

				response.reply "List of deployments:"

				if tasks["list"]["task"] == nil
					response.reply("- none")
				else
					tasks = tasks["list"]["task"]
					if tasks.is_a? Hash
						tasks = [ tasks ]
					end

					depls = tasks.select { |x| 
						x["metadata"]["taskType"]["$"] == "INITIAL" || 
						x["metadata"]["taskType"]["$"] == "UPGRADE" || 
						x["metadata"]["taskType"]["$"] == "UNDEPLOY" || 
						x["metadata"]["taskType"]["$"] == "ROLLBACK" }
					if depls.length == 0
						response.reply("- none")
					else
						for task in depls do
							botId = get_or_create_bot_id(task["@id"])
							response.reply(print_task(botId, task))
							update_room_task_id(response.message.room_object, botId)
						end

						message = response.message
						clear_conversation_context(message, "currentTaskBotId")
						clear_conversation_context(message, "currentApplicationId")
						clear_conversation_context(message, "currentVersionId")
						clear_conversation_context(message, "currentEnvironmentId")

					end
				end
			}
		end

		def list_environments(response)
			execute_with_error_reply(response) {
				rest_result = xld_rest_api(http).find_environment("")

				response.reply "List of environments:"

	            ci_list = rest_result["list"]
	            if ci_list["ci"] == nil
        			result.error = "- none"
        		else
		            cis = ci_list["ci"]
					if cis.is_a? Hash
						cis = [ cis ]
					end

					for env in cis do
						response.reply("- " + env["@ref"])
					end

					message = response.message
					clear_conversation_context(message, "currentEnvironmentId")

          		end
			}
		end

		def list_applications(response)
			execute_with_error_reply(response) {
				rest_result = xld_rest_api(http).find_application("")

				response.reply "List of applications:"

	            ci_list = rest_result["list"]
	            if ci_list["ci"] == nil
        			result.error = "- none"
        		else
		            cis = ci_list["ci"]
					if cis.is_a? Hash
						cis = [ cis ]
					end

					for env in cis do
						response.reply("- " + env["@ref"])
					end

					message = response.message
					clear_conversation_context(message, "currentApplicationId")

          		end
			}
		end

		def list_versions(response)
			execute_with_error_reply(response) {
				message = response.message

				appParam = determine_application(message, http, response.match_data[2])
				if appParam.error != nil
					response.reply appParam.error
					return
				end

				log.debug("Listing versions of application " + appParam.value)
				rest_result = xld_rest_api(http).find_version(appParam.value.full_id, "")

				response.reply "List of " + appParam.value + " versions:"

	            ci_list = rest_result["list"]
	            if ci_list["ci"] == nil
        			result.error = "- none"
        		else
		            cis = ci_list["ci"]
					if cis.is_a? Hash
						cis = [ cis ]
					end

					for env in cis do
						response.reply("- " + env["@ref"])
					end

					message = response.message
					clear_conversation_context(message, "currentVersionId")

          		end
			}
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

		def start_deployment(response)
			execute_with_error_reply(response) {
				message = response.message

				appParam = determine_application(message, http, response.match_data[2])
				if appParam.error != nil
					response.reply appParam.error
					return
				end

				versionParam = determine_version(message, http, appParam.value, response.match_data[4])
				if versionParam.error != nil
					response.reply versionParam.error
					return
				end

				envParam = determine_environment(message, http, response.match_data[6])
				if envParam.error != nil
					response.reply envParam.error
					return
				end

				output_default_message(response, appParam, versionParam, envParam)

				set_conversation_context(message, "currentApplicationId", appParam.value)
				set_conversation_context(message, "currentVersionId", versionParam.value)
				set_conversation_context(message, "currentEnvironmentId", envParam.value)
				
				appId = appParam.value
				envId = envParam.value
				versionId = versionParam.value
				# print "*** " + appId.full_id + ", " + versionId.full_id + ", " + envId.full_id + "\n"

				mode = determine_initial_or_update(http, appId, envId)
				preparedDeployment = xld_rest_api(http).prepare_deployment(appId, versionId, envId, mode)
				deploymentWithDeployeds = xld_rest_api(http).prepare_deployeds(preparedDeployment)
				taskId = xld_rest_api(http).create_deployment(deploymentWithDeployeds)

				botId = register_new_task(response, taskId)

				response.reply "Starting deployment of " + appParam.value + "-" + versionParam.value + " to " + envParam.value + " [" + botId + "]"

			  	xld_rest_api(http).start_task(taskId)
			}
		end

		def start_task(response)
			execute_with_error_reply(response) {
				botId = determine_command_bot_id(response.message, response.match_data[1])

				output_default_message(response, botId)

			  	set_conversation_context(response.message, "currentTaskBotId", botId.value)
			  	taskId = get_task_id(botId.value)
			  	response.reply "Starting task " + botId.value
			  	xld_rest_api(http).start_task(taskId)
			}
		end

		def abort_task(response)
			execute_with_error_reply(response) {
				botId = determine_command_bot_id(response.message, response.match_data[1])

				output_default_message(response, botId)

			  	set_conversation_context(response.message, "currentTaskBotId", botId.value)
			  	taskId = get_task_id(botId.value)
			  	response.reply "Aborting task " + botId.value
			  	xld_rest_api(http).abort_task(taskId)
			}
		end

		def cancel_task(response)
			execute_with_error_reply(response) {
				botId = determine_command_bot_id(response.message, response.match_data[1])

				output_default_message(response, botId)

			  	set_conversation_context(response.message, "currentTaskBotId", botId.value)
			  	taskId = get_task_id(botId.value)
			  	response.reply "Cancelling task " + botId.value
			  	xld_rest_api(http).cancel_task(taskId)
			}
		end

		def archive_task(response)
			execute_with_error_reply(response) {
				botId = determine_command_bot_id(response.message, response.match_data[1])

				output_default_message(response, botId)

			  	set_conversation_context(response.message, "currentTaskBotId", botId.value)
			  	taskId = get_task_id(botId.value)
			  	response.reply "Archiving task " + botId.value
			  	xld_rest_api(http).archive_task(taskId)
			}
		end

		def rollback_task(response)
			execute_with_error_reply(response) {
				botId = determine_command_bot_id(response.message, response.match_data[1])

				output_default_message(response, botId)

			  	taskId = get_task_id(botId.value)
			  	taskId = xld_rest_api(http).rollback_task(taskId)

			  	newBotId = register_new_task(response, taskId)

			  	response.reply "Rolling back task " + botId.value + " [" + newBotId + "]"

			  	xld_rest_api(http).start_task(taskId)
			}
		end

		def log_task(response)
			execute_with_error_reply(response) {
				botId = determine_command_bot_id(response.message, response.match_data[1])

				output_default_message(response, botId)

			  	set_conversation_context(response.message, "currentTaskBotId", botId.value)
			  	response.reply "Showing log of task " + botId.value
			  	show_log_tail(response, http, botId.value)
			}
		end

		def describe_task(response)
			execute_with_error_reply(response) {
				botId = determine_command_bot_id(response.message, response.match_data[1])

				output_default_message(response, botId)

			  	set_conversation_context(response.message, "currentTaskBotId", botId.value)
			  	response.reply "Describing task " + botId.value
			  	
			  	task = xld_rest_api(http).describe_task(get_task_id(botId.value))

			  	response.reply botId.value + "> XLD id: " + task["task"]["@id"]
			  	response.reply botId.value + "> State: " + task["task"]["@state"] + " (" + task["task"]["@state2"] + ")"
			  	response.reply botId.value + "> Owner: " + task["task"]["@owner"]

			  	begin
				  	response.reply botId.value + "> Start date: " + task["task"]["startDate"]["$"]
				  	response.reply botId.value + "> Completion date: " + task["task"]["completionDate"]["$"]
				rescue
					#ignore
				end
			}
		end

		#########
      	# HTTP route handlers

		def receive_task_status(request, response)
		  taskId = request.env["router.params"][:id]
		  status = request.env["router.params"][:status]
		  robot.trigger(:task_status, task_id: taskId, task_status: status)
		end

		Lita.register_handler(self)

    end
  end
end
