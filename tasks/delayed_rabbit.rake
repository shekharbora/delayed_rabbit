require "delayed_rabbit"

namespace :delayed_rabbit do
  desc "Enqueue a test job with delay (default 5000ms)"
  task :enqueue_test_job, [:delay_ms] => :environment do |t, args|
    delay_ms = Integer(args[:delay_ms] || 5000)

    job_data = {
      type: "test_job",
      timestamp: Time.now.to_i,
      message: "This is a test job enqueued with delayed_rabbit"
    }

    DelayedRabbit::JobPublisher.publish(job_data, delay_ms: delay_ms)
    puts "Enqueued test job with #{delay_ms}ms delay"
  end
end
