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

### 4. Use in Your Application

#### In Models/Services

```ruby
class UserNotifier
  def self.send_welcome_notification(user)
    DelayedRabbit::JobPublisher.publish(
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
# Enqueue a test job with 5 second delay
bundle exec rake delayed_rabbit:enqueue_test_job[5000]

# Enqueue a notification job
bundle exec rake jobs:enqueue_notification[5000,123]
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

# Create a publisher
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
    delay_ms = args[:delay_ms].to_i || 5000
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

#### Custom Exchange Configuration

```ruby
publisher = DelayedRabbit::JobPublisher.new(
  exchange_options: {
    type: "x-delayed-message",
    durable: true,
    auto_delete: false,
    arguments: {"x-delayed-type" => "direct"}  # Change to direct exchange
  }
)
```

#### Custom Queue Configuration

```ruby
publisher = DelayedRabbit::JobPublisher.new(
  queue_options: {
    durable: true,
    exclusive: false,
    auto_delete: false,
    arguments: {
      "x-dead-letter-exchange" => "dlx_exchange",
      "x-dead-letter-routing-key" => "dlx_key",
      "x-message-ttl" => 3600000  # 1 hour TTL
    }
  }
)
```

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

The test suite requires a running RabbitMQ instance with the delayed message plugin enabled. You can run tests with:

```bash
bundle exec rake test
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

1. **Plugin Not Enabled**
   - Ensure the delayed message plugin is enabled in RabbitMQ
   - Run: `rabbitmq-plugins enable rabbitmq_delayed_message_exchange`

2. **Connection Issues**
   - Verify RabbitMQ server is running
   - Check connection credentials
   - Verify network connectivity

3. **Message Not Received**
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
