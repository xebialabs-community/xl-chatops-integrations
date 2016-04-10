require 'multi_json'
require 'cobravsmongoose'

module Lita
  module Handlers
    # An XLD parameter
    class XldRestApi
      attr_accessor :url, :user, :password

      def initialize(http, url, user, password)
        @http = http
        @url = url
        @user = user
        @password = password

        @http.basic_auth(@user, @password)
      end
      
      def execute_get(url)
        http_response = @http.get(@url + url)
        if is_error(http_response)
          raise HttpError.new(http_response.status), "Error #{http_response.status} accessing GET URL " + url
        end
        http_response
      end

      def execute_post(url, body = nil)
        http_response = @http.post do |req|
          req.url @url + url
          req.headers['Content-Type'] = 'application/xml'
            req.body = body if body != nil
          end

        if is_error(http_response)
          raise HttpError.new(http_response.status), "Error #{http_response.status} accessing POST URL " + url
        end
        http_response
      end

      def do_get_tasks()
        http_response = execute_get("/task/current/all")
        MultiJson.load(CobraVsMongoose.xml_to_json(http_response.body))
      end

      def is_error(http_response)
        http_response.status < 200 || http_response.status > 299
      end

      def find_application(name)
        http_response = execute_get("/repository/query?type=udm.Application&namePattern=#{URI::encode('%' + name + '%')}")
        MultiJson.load(CobraVsMongoose.xml_to_json(http_response.body))
      end

      def find_version(applicationId, name)
        http_response = execute_get("/repository/query?type=udm.DeploymentPackage&parent=#{URI::encode(applicationId)}&namePattern=#{URI::encode('%' + name + '%')}")
        MultiJson.load(CobraVsMongoose.xml_to_json(http_response.body))
      end

      def find_environment(name)
        http_response = execute_get("/repository/query?type=udm.Environment&namePattern=#{URI::encode('%' + name + '%')}")
        MultiJson.load(CobraVsMongoose.xml_to_json(http_response.body))
      end

      def deployment_exists(application, environment)
        http_response = execute_get("/deployment/exists?application=#{URI::encode(application.full_id)}&environment=#{URI::encode(environment.full_id)}")
        exists = MultiJson.load(CobraVsMongoose.xml_to_json(http_response.body))
        return exists["boolean"]["$"] == "true"
      end

      def prepare_deployment(app, version, env, mode)
        if mode == "initial"
          params = "version=#{URI::encode(version.full_id)}&environment=#{URI::encode(env.full_id)}"
        else
          deployedApplication = "deployedApplication=#{URI::encode(env.full_id + '/' + app.to_s)}"
          params = "version=#{URI::encode(version.full_id)}&#{deployedApplication}"
        end

        http_response = execute_get("/deployment/prepare/#{mode}?#{params}")
        http_response.body
      end

      def prepare_deployeds(deployment)
        http_response = execute_post("/deployment/prepare/deployeds", deployment)
        http_response.body
      end

      def create_deployment(deployment)
        http_response = execute_post("/deployment/", deployment)
        http_response.body
      end

      def abort_task(taskId)
        http_response = execute_post("/task/" + taskId + "/abort")
      end

      def cancel_task(taskId)
        http_response = @http.delete do |req|
          req.headers['Content-Type'] = 'application/xml'
          req.url @url + "/task/" + taskId
        end

        if is_error(http_response)
          nil
        end
      end

      def archive_task(taskId)
        http_response = execute_post("/task/" + taskId + "/archive")
      end

      def start_task(taskId)
        http_response = execute_post("/task/" + taskId + "/start")
      end

      def rollback_task(taskId)
        begin
          http_response = execute_post("/deployment/rollback/" + taskId)
          http_response.body
        rescue HttpError => ex
          if ex.status == 500
            raise BotError, "This task can not be rolled back, task status must be STOPPED, FAILED, ABORTED or EXECUTED."
          else
            raise ex
          end
        end
      end

      def describe_task(taskId)
        http_response = execute_get("/task/" + taskId)
        MultiJson.load(CobraVsMongoose.xml_to_json(http_response.body))
      end

      def get_current_step_log(taskId)
        http_response = execute_get("/task/" + taskId)
        poll = MultiJson.load(CobraVsMongoose.xml_to_json(http_response.body))
        taskState = poll["task"]["@state"]

        stepId = poll["task"]["@currentStep"]
        # TO DO: include If-Modified-Since header
        http_response = execute_get("/task/" + taskId + "/step/" + stepId)
        stepState = MultiJson.load(CobraVsMongoose.xml_to_json(http_response.body))

        stepState["step"]["log"]["$"]
      end

    end
  end
end
