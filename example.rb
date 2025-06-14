require_relative "lib/delayed_rabbit"

# Example job data
job_data = {
  type: "email_notification",
  recipient: "user@example.com",
  subject: "Delayed Email",
  body: "This email was sent after a delay"
}

# Create a publisher with custom connection options
publisher = DelayedRabbit::JobPublisher.new(
  connection_options: {
    host: "localhost",
    port: 5672,
    user: "guest",
    password: "guest"
  }
)

# Publish a job with 5000ms (5 seconds) delay
message = publisher.publish(job_data, delay_ms: 5000)
puts "Published delayed job: #{message}"

# Close the connection
publisher.close
