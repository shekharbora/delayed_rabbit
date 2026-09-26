require "test_helper"
require "rails/railtie"
require "delayed_rabbit/railtie"

class RailtieTest < Minitest::Test
  def test_applies_rabbitmq_yml_settings
    settings = {
      host: "rabbitmq.internal", port: "5673", user: "app", password: "secret", vhost: "/app",
      automatic_recovery: true, network_recovery_interval: 10, exchange_type: "x-delayed-message", message_ttl: 3_600_000
    }

    config = DelayedRabbit::Railtie.apply(settings, DelayedRabbit::Configuration.new)

    assert_equal(
      {host: "rabbitmq.internal", port: 5673, user: "app", password: "secret", vhost: "/app",
       automatic_recovery: true, network_recovery_interval: 10},
      config.connection_options
    )
    assert_equal 3_600_000, config.queue_options[:arguments]["x-message-ttl"]
  end

  def test_blank_values_keep_defaults
    config = DelayedRabbit::Railtie.apply({host: nil, user: nil, port: nil}, DelayedRabbit::Configuration.new)

    assert_equal "localhost", config.connection_options[:host]
    assert_equal "guest", config.connection_options[:user]
    assert_equal 5672, config.connection_options[:port]
    refute config.queue_options[:arguments].key?("x-message-ttl")
  end

  def test_runs_before_app_initializers
    initializer = DelayedRabbit::Railtie.initializers.find { |i| i.name == "delayed_rabbit.configure" }

    assert_equal :load_config_initializers, initializer.before
  end
end
