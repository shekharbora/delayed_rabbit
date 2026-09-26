$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "delayed_rabbit"

require "minitest/autorun"
require "mocha/minitest"

module FakeRabbit
  # Stubs a Bunny session, channel, exchanges and queues so JobPublisher can be
  # built without a broker. Individual tests override these with expectations.
  def stub_rabbit
    @exchange = stub("exchange", publish: nil)
    @queue = stub("queue", bind: nil)
    @dead_letter_exchange = stub("dead_letter_exchange")
    @dead_letter_queue = stub("dead_letter_queue", bind: nil)

    @channel = stub("channel", open?: true, close: nil)
    @channel.stubs(:exchange).returns(@exchange)
    @channel.stubs(:fanout).returns(@dead_letter_exchange)
    @channel.stubs(:queue).returns(@queue)
    @channel.stubs(:queue).with(DelayedRabbit::Configuration::DEFAULT_DEAD_LETTER_QUEUE_NAME, anything).returns(@dead_letter_queue)

    @connection = stub("connection", open?: true, close: nil)
    @connection.stubs(:create_channel).returns(@channel)
    @connection
  end
end

class Minitest::Test
  include FakeRabbit

  def teardown
    DelayedRabbit.reset!
  end
end
