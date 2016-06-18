require 'multi_json'
require 'cobravsmongoose'

module Lita
  module Shared

    class Context
      attr_accessor :redis

      def initialize(redis, timeout)
        @redis = redis
        @timeout = timeout
      end

      def set_conversation_context(message, key, value)
          redis.set(message.user.id + ":" + message.room_object.id + ":" + key, value, { ex: timeout })
      end

      def get_conversation_context(message, key)
          redis.get(message.user.id + ":" + message.room_object.id + ":" + key)
      end

      def clear_conversation_context(message, key)
          redis.del(message.user.id + ":" + message.room_object.id + ":" + key)
      end

    end
  end
end
