require "delayed_rabbit/version"
require "delayed_rabbit/configuration"
require "delayed_rabbit/job_publisher"
require "delayed_rabbit/railtie" if defined?(Rails::Railtie)

module DelayedRabbit
  PUBLISHER_MUTEX = Mutex.new
  private_constant :PUBLISHER_MUTEX

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
      configuration
    end

    # Publishes through a shared, lazily created publisher so that callers do
    # not open a new TCP connection per message.
    def publish(job_data, **options)
      PUBLISHER_MUTEX.synchronize do
        @publisher = nil if @publisher && !@publisher.open?
        @publisher ||= JobPublisher.new
        @publisher.publish(job_data, **options)
      end
    end

    # Closes the shared publisher and restores the default configuration.
    def reset!
      PUBLISHER_MUTEX.synchronize do
        @publisher&.close
        @publisher = nil
      end
      @configuration = nil
    end
  end
end
