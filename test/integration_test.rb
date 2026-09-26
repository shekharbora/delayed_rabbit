require "test_helper"
require "securerandom"

# Runs against a real broker with the rabbitmq_delayed_message_exchange plugin:
#   RABBITMQ_INTEGRATION=1 bundle exec rake test
class IntegrationTest < Minitest::Test
  def setup
    skip "set RABBITMQ_INTEGRATION=1 to run against a real broker" unless ENV["RABBITMQ_INTEGRATION"]

    suffix = SecureRandom.hex(4)
    @config = DelayedRabbit::Configuration.new
    @config.connection_options = @config.connection_options.merge(host: ENV.fetch("RABBITMQ_HOST", "localhost"))
    @config.exchange_name = "delayed_rabbit_test.#{suffix}"
    @config.queue_name = "delayed_rabbit_test.#{suffix}.queue"
    @config.dead_letter_exchange_name = nil
    @publisher = DelayedRabbit::JobPublisher.new(config: @config)
  end

  def teardown
    return unless @publisher

    @publisher.queue.delete
    @publisher.exchange.delete
    @publisher.close
    super
  end

  def test_message_is_held_for_the_delay
    @publisher.publish({job: "delayed"}, delay_ms: 1500)

    sleep 0.5
    assert_equal 0, @publisher.queue.message_count, "message arrived before the delay elapsed"

    _delivery, _properties, body = wait_for_message(timeout: 5)
    refute_nil body, "message never arrived"
    assert_equal({"job" => "delayed"}, JSON.parse(body)["job_data"])
  end

  private

  def wait_for_message(timeout:)
    deadline = Time.now + timeout
    while Time.now < deadline
      delivery = @publisher.queue.pop
      return delivery if delivery.last
      sleep 0.1
    end
    nil
  end
end
