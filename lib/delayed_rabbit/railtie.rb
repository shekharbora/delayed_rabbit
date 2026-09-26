require "delayed_rabbit"

module DelayedRabbit
  class Railtie < Rails::Railtie
    CONNECTION_KEYS = %i[host port user password vhost automatic_recovery network_recovery_interval].freeze

    # Runs before config/initializers, so settings in the app's initializer
    # take precedence over config/rabbitmq.yml.
    initializer "delayed_rabbit.configure", before: :load_config_initializers do |app|
      next unless app.root.join("config", "rabbitmq.yml").exist?

      DelayedRabbit::Railtie.apply(app.config_for(:rabbitmq), DelayedRabbit.configuration)
    end

    rake_tasks do
      load File.expand_path("../../tasks/delayed_rabbit.rake", __dir__)
    end

    def self.apply(settings, config)
      settings = settings.to_h.transform_keys(&:to_sym)

      config.connection_options = config.connection_options.merge(settings.slice(*CONNECTION_KEYS).compact)
      config.connection_options[:port] = Integer(config.connection_options[:port])

      if settings[:exchange_type]
        config.exchange_options = config.exchange_options.merge(type: settings[:exchange_type])
      end

      if settings[:message_ttl]
        arguments = config.queue_options.fetch(:arguments, {}).merge("x-message-ttl" => Integer(settings[:message_ttl]))
        config.queue_options = config.queue_options.merge(arguments: arguments)
      end

      config
    end
  end
end
