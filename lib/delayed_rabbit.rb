require "delayed_rabbit/version"
require "delayed_rabbit/job_publisher"
require "delayed_rabbit/railtie" if defined?(Rails)

module DelayedRabbit
  class << self
    attr_accessor :configuration
  
    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
    end
  end

  class Configuration
    attr_accessor :connection_options, :exchange_options, :queue_options

    def initialize
      @connection_options = {
        host: "localhost",
        port: 5672,
        user: "guest",
        password: "guest"
      }
      @exchange_options = {
        type: "x-delayed-message",
        durable: true,
        arguments: {"x-delayed-type" => "topic"}
      }
      @queue_options = {
        durable: true,
        arguments: {
          "x-dead-letter-exchange" => "delayed_jobs",
          "x-dead-letter-routing-key" => "delayed_jobs"
        }
      }
    end
  end
end
