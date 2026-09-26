module DelayedRabbit
  class Configuration
    DEFAULT_EXCHANGE_NAME = "delayed_jobs"
    DEFAULT_QUEUE_NAME = "delayed_jobs_queue"
    DEFAULT_ROUTING_KEY = "delayed_jobs"
    DEFAULT_DEAD_LETTER_EXCHANGE_NAME = "delayed_jobs.dlx"
    DEFAULT_DEAD_LETTER_QUEUE_NAME = "delayed_jobs.dead"

    attr_accessor :connection_options, :exchange_options, :queue_options,
                  :exchange_name, :queue_name, :routing_key,
                  :dead_letter_exchange_name, :dead_letter_queue_name

    def initialize
      @exchange_name = DEFAULT_EXCHANGE_NAME
      @queue_name = DEFAULT_QUEUE_NAME
      @routing_key = DEFAULT_ROUTING_KEY
      # Rejected or expired messages are routed here instead of back into the
      # work queue. Set to nil to disable dead-lettering.
      @dead_letter_exchange_name = DEFAULT_DEAD_LETTER_EXCHANGE_NAME
      @dead_letter_queue_name = DEFAULT_DEAD_LETTER_QUEUE_NAME

      @connection_options = {
        host: "localhost",
        port: 5672,
        user: "guest",
        password: "guest",
        vhost: "/"
      }
      @exchange_options = {
        type: "x-delayed-message",
        durable: true,
        arguments: {"x-delayed-type" => "topic"}
      }
      # Merged over the defaults (including the dead-letter arguments), so only
      # the extra settings need to be given here.
      @queue_options = {
        durable: true,
        arguments: {}
      }
    end
  end
end
