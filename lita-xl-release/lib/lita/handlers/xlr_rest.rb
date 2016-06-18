require 'multi_json'

module Lita
  module Handlers

    class XlrRestApi
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
          raise Lita::Shared::HttpError.new(http_response.status), "Error #{http_response.status} accessing GET URL " + url
        end
        http_response
      end

      def execute_post(url, body = nil)
        http_response = @http.post do |req|
          req.url @url + url
          req.headers['Content-Type'] = 'application/json'
            req.body = body if body != nil
          end

        if is_error(http_response)
          raise Lita::Shared::HttpError.new(http_response.status), "Error #{http_response.status} accessing POST URL " + url
        end
        http_response
      end

      def get_releases()
        http_response = execute_post("/releases/search", "{ \"active\": \"true\"}")
        MultiJson.load(http_response.body)
      end

      def complete_task(taskId, comment = "Complete")
        request_id = taskId.gsub(/-/, '/')
        http_response = execute_post("/api/v1/tasks/Applications/#{request_id}/complete", "{ \"comment\": \"#{comment}\" }")
        MultiJson.load(http_response.body)
      end

      def is_error(http_response)
        http_response.status < 200 || http_response.status > 299
      end

    end
  end
end
