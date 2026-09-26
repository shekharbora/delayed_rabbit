require "test_helper"

class ConfigurationTest < Minitest::Test
  def test_configuration_is_available_without_configure
    assert_instance_of DelayedRabbit::Configuration, DelayedRabbit.configuration
  end

  def test_default_connection_options
    options = DelayedRabbit.configuration.connection_options

    assert_equal "localhost", options[:host]
    assert_equal 5672, options[:port]
    assert_equal "guest", options[:user]
    assert_equal "guest", options[:password]
    assert_equal "/", options[:vhost]
  end

  def test_default_names
    config = DelayedRabbit.configuration

    assert_equal "delayed_jobs", config.exchange_name
    assert_equal "delayed_jobs_queue", config.queue_name
    assert_equal "delayed_jobs", config.routing_key
    assert_equal "delayed_jobs.dlx", config.dead_letter_exchange_name
    assert_equal "delayed_jobs.dead", config.dead_letter_queue_name
  end

  def test_default_exchange_options
    options = DelayedRabbit.configuration.exchange_options

    assert_equal "x-delayed-message", options[:type]
    assert_equal true, options[:durable]
    assert_equal "topic", options[:arguments]["x-delayed-type"]
  end

  def test_configures_with_block
    DelayedRabbit.configure do |config|
      config.connection_options = {host: "rabbitmq.example.com", port: 5673}
      config.queue_name = "custom_queue"
    end

    assert_equal "rabbitmq.example.com", DelayedRabbit.configuration.connection_options[:host]
    assert_equal "custom_queue", DelayedRabbit.configuration.queue_name
  end

  def test_reset_restores_defaults
    DelayedRabbit.configure { |config| config.queue_name = "custom_queue" }
    DelayedRabbit.reset!

    assert_equal "delayed_jobs_queue", DelayedRabbit.configuration.queue_name
  end
end
