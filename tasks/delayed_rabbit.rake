require "delayed_rabbit"

namespace :delayed_rabbit do
  desc "Enqueue a test job with delay"
  task :enqueue_test_job, [:delay_ms] => :environment do |t, args|
    delay_ms = args[:delay_ms].to_i || 5000 # Default to 5 seconds
    
    job_data = {
      type: "test_job",
      timestamp: Time.now.to_i,
      message: "This is a test job enqueued with delayed_rabbit"
    }

    DelayedRabbit::JobPublisher.publish(job_data, delay_ms: delay_ms)
    puts "Enqueued test job with #{delay_ms}ms delay"
  end
end
