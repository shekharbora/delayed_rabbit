# Connection settings are read from config/rabbitmq.yml for the current
# environment. Anything set here overrides that file.
DelayedRabbit.configure do |config|
  # Exchange and queue names
  # config.exchange_name = "delayed_jobs"
  # config.queue_name = "delayed_jobs_queue"
  # config.routing_key = "delayed_jobs"

  # Rejected or expired messages go to this exchange/queue (nil disables it)
  # config.dead_letter_exchange_name = "delayed_jobs.dlx"
  # config.dead_letter_queue_name = "delayed_jobs.dead"

  # Extra queue arguments are merged into the defaults. Changing arguments of a
  # queue that already exists makes RabbitMQ reject the declaration
  # (PRECONDITION_FAILED); delete the queue first.
  # config.queue_options = {
  #   durable: true,
  #   arguments: {"x-message-ttl" => 3_600_000}
  # }
end
