require "rails/generators"

module DelayedRabbit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        template "initializer.rb", "config/initializers/delayed_rabbit.rb"
      end

      def create_rabbitmq_config
        template "rabbitmq.yml", "config/rabbitmq.yml"
      end
    end
  end
end
