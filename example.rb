require_relative "lib/delayed_rabbit"

DelayedRabbit.configure do |config|
  config.connection_options = {
    host: "localhost",
    port: 5672,
    user: "guest",
    password: "guest"
  }
end

job_data = {
  type: "email_notification",
  recipient: "user@example.com",
  subject: "Delayed Email",
  body: "This email was sent after a delay"
}

# Publish a job with 5000ms (5 seconds) delay
publisher = DelayedRabbit::JobPublisher.new
message = publisher.publish(job_data, delay_ms: 5000)
puts "Published delayed job: #{message}"
publisher.close
