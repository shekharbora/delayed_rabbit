# Delayed Rabbit

A lightweight Ruby gem for scheduling delayed background jobs using RabbitMQ's delayed message exchange plugin.

## Features

- Schedules jobs with custom delays using RabbitMQ's x-delayed-message plugin
- Uses JSON serialization for job data
- Configurable exchange and queue settings
- Simple API for publishing delayed jobs
- Rails integration support
- Automatic connection management
- Persistent message delivery
- Support for custom routing keys
- Dead-letter queue support

> delayed_rabbit only **publishes** jobs. Consume `delayed_jobs_queue` with your own
> worker (e.g. Bunny, Sneakers or a service in another language).

## Requirements

- Ruby 3.2+
- RabbitMQ 3.8+ with x-delayed-message plugin enabled
- Bunny gem (~> 2.18)
- JSON serialization support

## Installation

### Enabling RabbitMQ Plugin

Before using this gem, you need to enable the delayed message plugin in RabbitMQ:

```bash
rabbitmq-plugins enable rabbitmq_delayed_message_exchange
```

### Ruby Gem Installation

Add this line to your application's Gemfile:

```ruby
gem 'delayed_rabbit'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install delayed_rabbit
```

## Rails Integration

### 1. Install the Gem

Add to your Gemfile:

```ruby
gem 'delayed_rabbit'
```

### 2. Run the Installer

Run the generator to set up configuration files:

```bash
rails generate delayed_rabbit:install
```

This will create:
- `config/initializers/delayed_rabbit.rb` - Main configuration file
- `config/rabbitmq.yml` - Environment-specific RabbitMQ settings

### 3. Configure RabbitMQ

Edit `config/rabbitmq.yml` with your RabbitMQ settings:

```yaml
development:
  host: localhost
  port: 5672
  user: guest
  password: guest
  vhost: /

production:
  host: <%= ENV['RABBITMQ_HOST'] %>
  port: <%= ENV['RABBITMQ_PORT'] || 5672 %>
  user: <%= ENV['RABBITMQ_USER'] %>
  password: <%= ENV['RABBITMQ_PASSWORD'] %>
  vhost: <%= ENV['RABBITMQ_VHOST'] || '/' %>
```

Settings from `rabbitmq.yml` are loaded before the app's initializers run, so anything set in
`config/initializers/delayed_rabbit.rb` overrides them. If the file is missing, the defaults are used.

### 4. Use in Your Application

#### In Models/Services

```ruby
class UserNotifier
  def self.send_welcome_notification(user)
    DelayedRabbit.publish(
      {
        type: "welcome_email",
        user_id: user.id,
        email: user.email
      },
      delay_ms: 5000,  # 5 seconds delay
      routing_key: "notifications.welcome"
    )
  end
end
```

`DelayedRabbit.publish` reuses one shared connection (guarded by a mutex) across calls.
`DelayedRabbit::JobPublisher.publish` takes the same arguments but opens and closes a
connection for each message.

#### In Controllers

```ruby
class UsersController < ApplicationController
  def create
    user = User.create(user_params)
    UserNotifier.send_welcome_notification(user)
    redirect_to root_path, notice: 'User created successfully'
  end
end
```

#### Using Rake Tasks

The gem provides a rake task for testing:

```bash
# Enqueue a test job (delay defaults to 5000ms)
bundle exec rake delayed_rabbit:enqueue_test_job
bundle exec rake delayed_rabbit:enqueue_test_job[10000]
```

## Usage (Non-Rails)

If you're not using Rails:

```ruby
require 'delayed_rabbit'

# Configure manually
DelayedRabbit.configure do |config|
  config.connection_options = {
    host: "localhost",
    port: 5672,
    user: "guest",
    password: "guest"
  }
end

# Create a publisher (uses DelayedRabbit.configuration)
publisher = DelayedRabbit::JobPublisher.new

# Publish a job
publisher.publish(
  {
    type: "email_notification",
    recipient: "user@example.com"
  },
  delay_ms: 5000
)

# Close connection
publisher.close
```

### Using with Rails

1. Add the gem to your Gemfile
2. Run the rake task to enqueue a test job:

```bash
bundle exec rake delayed_rabbit:enqueue_test_job[5000]
```

You can also create your own rake tasks for specific job types:

```ruby
namespace :jobs do
  desc "Enqueue a notification job"
  task :enqueue_notification, [:delay_ms, :user_id] => :environment do |t, args|
    delay_ms = Integer(args[:delay_ms] || 5000)
    user_id = args[:user_id]
    
    job_data = {
      type: "notification",
      user_id: user_id,
      message: "Welcome notification"
    }

    DelayedRabbit::JobPublisher.publish(job_data, delay_ms: delay_ms, routing_key: "notifications.#{user_id}")
  end
end
```

### Advanced Usage

Options passed to `JobPublisher.new` are merged over `DelayedRabbit.configuration`. The
`arguments` hashes are merged key by key, so you only need to pass the arguments you add.
To reuse an existing Bunny session, pass `connection:`; the publisher then won't close it.

#### Custom Names and Dead-Lettering

```ruby
DelayedRabbit.configure do |config|
  config.exchange_name = "delayed_jobs"
  config.queue_name = "delayed_jobs_queue"
  config.routing_key = "delayed_jobs"

  # Rejected or expired messages are routed to this fanout exchange and queue.
  # Set dead_letter_exchange_name to nil to disable.
  config.dead_letter_exchange_name = "delayed_jobs.dlx"
  config.dead_letter_queue_name = "delayed_jobs.dead"
end
```

#### Custom Exchange Configuration

```ruby
publisher = DelayedRabbit::JobPublisher.new(
  exchange_options: {
    arguments: {"x-delayed-type" => "direct"}  # Change to direct exchange
  }
)
```

#### Custom Queue Configuration

```ruby
publisher = DelayedRabbit::JobPublisher.new(
  queue_options: {
    arguments: {"x-message-ttl" => 3600000}  # 1 hour TTL, then dead-lettered
  }
)
```

RabbitMQ rejects a declaration whose options differ from an existing exchange or queue
(`PRECONDITION_FAILED`). After changing queue arguments, delete the queue so it can be
declared again.

#### Using with Rails Environment

You can configure different settings based on Rails environment:

```ruby
# config/initializers/delayed_rabbit.rb
DelayedRabbit.configure do |config|
  config.connection_options = {
    host: Rails.env.production? ? "rabbitmq-prod" : "localhost",
    port: 5672,
    user: Rails.application.credentials.rabbitmq[:user],
    password: Rails.application.credentials.rabbitmq[:password]
  }
end
```

## Configuration Options

### Connection Options

- `host`: RabbitMQ server hostname
- `port`: RabbitMQ server port (default: 5672)
- `user`: Username for authentication
- `password`: Password for authentication
- `vhost`: Virtual host to connect to (default: "/")
- `automatic_recovery`: Enable automatic connection recovery
- `network_recovery_interval`: Time between recovery attempts

### Exchange Options

- `type`: Exchange type (default: "x-delayed-message")
- `durable`: If true, exchange will survive broker restarts
- `auto_delete`: If true, exchange will be deleted when last queue unbinds
- `arguments`: Additional exchange arguments

### Queue Options

- `durable`: If true, queue will survive broker restarts
- `exclusive`: If true, queue can only be consumed by this connection
- `auto_delete`: If true, queue will be deleted when last consumer disconnects
- `arguments`: Additional queue arguments (e.g., TTL, dead-letter exchange)

## Development

### Setting Up Development Environment

1. Clone the repository
2. Install dependencies:
```bash
gem install bundler
bundle install
```

3. Run the test suite:
```bash
bundle exec rake test
```

4. Start the development console:
```bash
bundle exec irb -Ilib -rdelayed_rabbit
```

### Running Tests

The unit tests use mocks and need no broker:

```bash
bundle exec rake test
```

The integration test publishes a delayed message to a real broker that has the delayed
message plugin enabled:

```bash
RABBITMQ_INTEGRATION=1 bundle exec rake test
```

### Releasing a New Version

1. Update the version number in `lib/delayed_rabbit/version.rb`
2. Run the release command:
```bash
bundle exec rake release
```

This will:
- Create a git tag for the version
- Push git commits and tags
- Push the `.gem` file to rubygems.org

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

## Troubleshooting

### Common Issues

1. **Plugin Not Enabled** (`PRECONDITION_FAILED - invalid exchange type 'x-delayed-message'`)
   - Ensure the delayed message plugin is enabled in RabbitMQ
   - Run: `rabbitmq-plugins enable rabbitmq_delayed_message_exchange`

2. **`PRECONDITION_FAILED - inequivalent arg ...`**
   - An exchange or queue with the same name already exists with different settings
     (versions before 1.1.0 declared `delayed_jobs` as a plain `topic` exchange)
   - Delete it, e.g. `rabbitmqctl delete_exchange delayed_jobs` / `rabbitmqctl delete_queue delayed_jobs_queue`

3. **Connection Issues**
   - Verify RabbitMQ server is running
   - Check connection credentials
   - Verify network connectivity

4. **Message Not Received**
   - Check if exchange exists
   - Verify queue bindings
   - Check message TTL settings

### Debugging Tips

1. Enable Bunny logging:
```ruby
Bunny.logger.level = Logger::DEBUG
```

2. Use RabbitMQ management UI to:
   - Monitor exchanges and queues
   - Check message delivery
   - View connection status

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Support

For support, please:
1. Check the documentation
2. Search existing issues
3. Open a new issue if needed
4. For urgent issues, consider professional support options

## Security

If you discover a security vulnerability, please contact the maintainers directly instead of opening a public issue. We will work to address the vulnerability as quickly as possible.
