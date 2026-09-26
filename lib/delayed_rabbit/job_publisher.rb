require "bunny"
require "json"

module DelayedRabbit
  class JobPublisher
    # The delayed message exchange plugin stores the delay as an unsigned 32-bit integer.
    MAX_DELAY_MS = 2**32 - 1

    attr_reader :connection, :channel, :exchange, :queue, :config

    # Pass `connection:` to reuse an existing Bunny session; the publisher will
    # not close a connection it did not open.
    def initialize(connection_options: nil, exchange_options: nil, queue_options: nil,
                   connection: nil, config: DelayedRabbit.configuration)
      @config = config
      @owns_connection = connection.nil?
      @connection = connection || Bunny.new(config.connection_options.merge(connection_options || {}))
      @connection.start unless @connection.open?
      @channel = @connection.create_channel

      @exchange_options = merge_options(config.exchange_options, exchange_options)
      @exchange = @channel.exchange(config.exchange_name, @exchange_options)

      @queue_options = merge_options(default_queue_options, config.queue_options, queue_options)
      @queue = @channel.queue(config.queue_name, @queue_options)
      @queue.bind(@exchange, routing_key: config.routing_key)

      declare_dead_letter_queue
    end

    def publish(job_data, delay_ms: 0, routing_key: config.routing_key)
      unless delay_ms.is_a?(Integer) && delay_ms.between?(0, MAX_DELAY_MS)
        raise ArgumentError, "Delay must be an integer between 0 and #{MAX_DELAY_MS}"
      end

      message = {
        job_data: job_data,
        timestamp: Time.now.to_i
      }.to_json

      @exchange.publish(
        message,
        headers: {"x-delay" => delay_ms},
        routing_key: routing_key,
        persistent: true,
        content_type: "application/json"
      )

      message
    end

    def open?
      @connection.open?
    end

    def close
      if @owns_connection
        @connection.close if @connection.open?
      elsif @channel.open?
        @channel.close
      end
    end

    def self.publish(job_data, delay_ms: 0, routing_key: nil, **options)
      publisher = new(**options)
      publisher.publish(job_data, delay_ms: delay_ms, routing_key: routing_key || publisher.config.routing_key)
    ensure
      publisher&.close
    end

    private

    def default_queue_options
      return {durable: true} unless config.dead_letter_exchange_name

      {durable: true, arguments: {"x-dead-letter-exchange" => config.dead_letter_exchange_name}}
    end

    def declare_dead_letter_queue
      return unless config.dead_letter_exchange_name

      dead_letter_exchange = @channel.fanout(config.dead_letter_exchange_name, durable: true)
      return unless config.dead_letter_queue_name

      @channel.queue(config.dead_letter_queue_name, durable: true).bind(dead_letter_exchange)
    end

    # Shallow merge, except that queue/exchange `arguments` are merged key by key
    # so adding one argument does not drop the defaults.
    def merge_options(*option_hashes)
      option_hashes.compact.reduce({}) do |merged, options|
        merged.merge(options) do |key, old_value, new_value|
          key == :arguments && old_value.is_a?(Hash) && new_value.is_a?(Hash) ? old_value.merge(new_value) : new_value
        end
      end
    end
  end
end
