require "test_helper"

class JobPublisherTest < Minitest::Test
  def setup
    stub_rabbit
  end

  def build_publisher(**options)
    DelayedRabbit::JobPublisher.new(connection: @connection, **options)
  end

  def test_declares_delayed_message_exchange
    @channel.expects(:exchange)
      .with("delayed_jobs", has_entries(type: "x-delayed-message", durable: true, arguments: {"x-delayed-type" => "topic"}))
      .returns(@exchange)

    build_publisher
  end

  def test_declares_queue_with_separate_dead_letter_exchange
    @channel.expects(:queue)
      .with("delayed_jobs_queue", {durable: true, arguments: {"x-dead-letter-exchange" => "delayed_jobs.dlx"}})
      .returns(@queue)
    @queue.expects(:bind).with(@exchange, routing_key: "delayed_jobs")

    build_publisher
  end

  def test_declares_and_binds_dead_letter_queue
    @channel.expects(:fanout).with("delayed_jobs.dlx", durable: true).returns(@dead_letter_exchange)
    @dead_letter_queue.expects(:bind).with(@dead_letter_exchange)

    build_publisher
  end

  def test_dead_lettering_can_be_disabled
    DelayedRabbit.configuration.dead_letter_exchange_name = nil
    @channel.expects(:fanout).never
    @channel.expects(:queue).with("delayed_jobs_queue", {durable: true, arguments: {}}).returns(@queue)

    build_publisher
  end

  def test_uses_configured_names
    DelayedRabbit.configure do |config|
      config.exchange_name = "app_exchange"
      config.queue_name = "app_queue"
      config.routing_key = "app.jobs"
    end
    @channel.expects(:exchange).with("app_exchange", anything).returns(@exchange)
    @channel.expects(:queue).with("app_queue", anything).returns(@queue)
    @queue.expects(:bind).with(@exchange, routing_key: "app.jobs")

    build_publisher
  end

  def test_custom_queue_arguments_are_merged_with_defaults
    DelayedRabbit.configuration.queue_options = {durable: true, arguments: {"x-message-ttl" => 1000}}
    expected_arguments = {"x-dead-letter-exchange" => "delayed_jobs.dlx", "x-message-ttl" => 1000, "x-max-length" => 10}
    @channel.expects(:queue)
      .with("delayed_jobs_queue", {durable: true, arguments: expected_arguments})
      .returns(@queue)

    build_publisher(queue_options: {arguments: {"x-max-length" => 10}})
  end

  def test_custom_exchange_options_are_merged_with_defaults
    @channel.expects(:exchange)
      .with("delayed_jobs", has_entries(type: "x-delayed-message", durable: false, arguments: {"x-delayed-type" => "direct"}))
      .returns(@exchange)

    build_publisher(exchange_options: {durable: false, arguments: {"x-delayed-type" => "direct"}})
  end

  def test_builds_bunny_session_from_configuration_and_overrides
    DelayedRabbit.configuration.connection_options = {host: "rabbitmq.example.com", port: 5673, user: "app"}
    Bunny.expects(:new).with({host: "rabbitmq.example.com", port: 5673, user: "app", password: "secret"}).returns(@connection)

    DelayedRabbit::JobPublisher.new(connection_options: {password: "secret"})
  end

  def test_starts_connection_that_is_not_open
    @connection.stubs(:open?).returns(false)
    @connection.expects(:start)

    build_publisher
  end

  def test_publishes_job_with_delay
    job_data = {job: "test_job", args: [1, 2, 3]}
    @exchange.expects(:publish).with do |message, options|
      body = JSON.parse(message)
      body["job_data"] == {"job" => "test_job", "args" => [1, 2, 3]} &&
        (body["timestamp"] - Time.now.to_i).abs <= 1 &&
        options == {headers: {"x-delay" => 1000}, routing_key: "delayed_jobs", persistent: true, content_type: "application/json"}
    end

    message = build_publisher.publish(job_data, delay_ms: 1000)

    assert_equal({"job" => "test_job", "args" => [1, 2, 3]}, JSON.parse(message)["job_data"])
  end

  def test_publishes_without_delay_by_default
    @exchange.expects(:publish).with(anything, has_entry(headers: {"x-delay" => 0}))

    build_publisher.publish({job: "test_job"})
  end

  def test_publishes_with_custom_routing_key
    @exchange.expects(:publish).with(anything, has_entry(routing_key: "notifications.welcome"))

    build_publisher.publish({job: "test_job"}, routing_key: "notifications.welcome")
  end

  def test_rejects_invalid_delays
    publisher = build_publisher

    [-1, 1.5, nil, "1000", DelayedRabbit::JobPublisher::MAX_DELAY_MS + 1].each do |delay_ms|
      assert_raises(ArgumentError, "expected #{delay_ms.inspect} to be rejected") do
        publisher.publish({job: "test_job"}, delay_ms: delay_ms)
      end
    end
  end

  def test_close_leaves_injected_connection_open
    @connection.expects(:close).never
    @channel.expects(:close)

    build_publisher.close
  end

  def test_close_closes_owned_connection
    Bunny.stubs(:new).returns(@connection)
    @connection.expects(:close)

    DelayedRabbit::JobPublisher.new.close
  end

  def test_class_publish_closes_connection_after_publishing
    Bunny.stubs(:new).returns(@connection)
    @exchange.expects(:publish).with(anything, has_entry(headers: {"x-delay" => 500}))
    @connection.expects(:close)

    DelayedRabbit::JobPublisher.publish({job: "test_job"}, delay_ms: 500)
  end

  def test_class_publish_closes_connection_when_publishing_fails
    Bunny.stubs(:new).returns(@connection)
    @exchange.stubs(:publish).raises(Bunny::ConnectionClosedError.new(@channel))
    @connection.expects(:close)

    assert_raises(Bunny::ConnectionClosedError) do
      DelayedRabbit::JobPublisher.publish({job: "test_job"})
    end
  end

  def test_module_publish_reuses_one_connection
    Bunny.expects(:new).once.returns(@connection)
    @exchange.expects(:publish).twice

    DelayedRabbit.publish({job: "first"})
    DelayedRabbit.publish({job: "second"}, delay_ms: 100)
  end

  def test_module_publish_reconnects_after_connection_closes
    Bunny.expects(:new).twice.returns(@connection)
    DelayedRabbit.publish({job: "first"})

    @connection.stubs(:open?).returns(false)
    @connection.stubs(:start)
    DelayedRabbit.publish({job: "second"})
  end
end
