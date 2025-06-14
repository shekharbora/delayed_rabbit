# Configure Delayed Rabbit
DelayedRabbit.configure do |config|
  # Connection settings
  config.connection_options = {
    host: ENV['RABBITMQ_HOST'] || "localhost",
    port: ENV['RABBITMQ_PORT'] || 5672,
    user: ENV['RABBITMQ_USER'] || "guest",
    password: ENV['RABBITMQ_PASSWORD'] || "guest",
    vhost: ENV['RABBITMQ_VHOST'] || "/",
    automatic_recovery: true,
    network_recovery_interval: 10
  }

  # Exchange settings
  config.exchange_options = {
    type: "x-delayed-message",
    durable: true,
    arguments: {"x-delayed-type" => "topic"}
  }

  # Queue settings
  config.queue_options = {
    durable: true,
    arguments: {
      "x-dead-letter-exchange" => "delayed_jobs",
      "x-dead-letter-routing-key" => "delayed_jobs",
      "x-message-ttl" => 3600000  # 1 hour TTL
    }
  }
end
