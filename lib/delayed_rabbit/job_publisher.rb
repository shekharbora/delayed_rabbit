require "bunny"
require "json"

module DelayedRabbit
  class JobPublisher
    def self.deep_symbolize_keys(hash)
      hash.transform_keys(&:to_sym).transform_values do |value|
        case value
        when Hash
          deep_symbolize_keys(value)
        when Array
          value.map { |v| v.is_a?(Hash) ? deep_symbolize_keys(v) : v }
        else
          value
        end
      end
    end
  end
end

module DelayedRabbit
  class JobPublisher
    DEFAULT_EXCHANGE_NAME = "delayed_jobs"
    DEFAULT_EXCHANGE_TYPE = "x-delayed-message"
    DEFAULT_DELAYED_QUEUE_NAME = "delayed_jobs_queue"
    DEFAULT_DELAYED_QUEUE_ROUTING_KEY = "delayed_jobs"

    attr_reader :connection, :channel, :exchange

    def initialize(connection_options = {}, exchange_options = {}, queue_options = {}, connection: nil, channel: nil)
      @connection = connection || Bunny.new(connection_options)
      @channel = channel || @connection.create_channel
      
      # Configure exchange
      @exchange_options = {
        type: DEFAULT_EXCHANGE_TYPE,
        durable: true,
        arguments: {"x-delayed-type" => "topic"}
      }.merge(exchange_options)
      
      @exchange = @channel.topic(DEFAULT_EXCHANGE_NAME, @exchange_options)
      
      # Configure queue
      @queue_options = {
        durable: true,
        arguments: {
          "x-dead-letter-exchange" => DEFAULT_EXCHANGE_NAME,
          "x-dead-letter-routing-key" => DEFAULT_DELAYED_QUEUE_ROUTING_KEY
        }
      }.merge(queue_options)
      
      @queue = @channel.queue(DEFAULT_DELAYED_QUEUE_NAME, @queue_options)
      @queue.bind(@exchange, routing_key: DEFAULT_DELAYED_QUEUE_ROUTING_KEY)
    end

    def publish(job_data, delay_ms: 0, routing_key: DEFAULT_DELAYED_QUEUE_ROUTING_KEY)
      raise ArgumentError, "Delay must be a non-negative integer" if delay_ms < 0

      message = {
        job_data: job_data,
        timestamp: Time.now.to_i
      }

      puts "Publishing message: #{message.inspect}"
      puts "Job data: #{job_data.inspect}"

      puts '=====================================>'
      @exchange.publish(
        message.to_json,
        headers: {"x-delay" => delay_ms},
        routing_key: routing_key,
        persistent: true
      )
      # Return the original job_data hash
      puts "Returning: #{job_data.inspect}"
      message[:job_data] = message[:job_data].deep_symbolize_keys
      message[:job_data]
    end

    def close
      @connection.close if @connection.open?
    end

    def self.publish(job_data, delay_ms: 0, routing_key: DEFAULT_DELAYED_QUEUE_ROUTING_KEY, **options)
      publisher = new(**options)
      message = publisher.publish(job_data, delay_ms: delay_ms, routing_key: routing_key)
      publisher.close
      message
    end
  end
end
