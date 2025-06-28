require "delayed_rabbit"

module DelayedRabbit
  class Railtie < Rails::Railtie
    config.after_initialize do
      DelayedRabbit.configure do |config|
        config.connection_options = {
          host: Rails.application.config_for(:rabbitmq)&.dig(:host) || "localhost",
          port: Rails.application.config_for(:rabbitmq)&.dig(:port) || 5672,
          user: Rails.application.config_for(:rabbitmq)&.dig(:user) || "guest",
          password: Rails.application.config_for(:rabbitmq)&.dig(:password) || "guest",
          vhost: Rails.application.config_for(:rabbitmq)&.dig(:vhost) || "/"
        }
        
        config.exchange_options = {
          type: Rails.application.config_for(:rabbitmq)&.dig(:exchange_type) || "x-delayed-message",
          durable: true,
          arguments: {"x-delayed-type" => "topic"}
        }
        
        config.queue_options = {
          durable: true,
          arguments: {
            "x-dead-letter-exchange" => "delayed_jobs",
            "x-dead-letter-routing-key" => "delayed_jobs"
          }
        }
      end
    end

    rake_tasks do
      load "tasks/delayed_rabbit.rake"
    end
  end
end
