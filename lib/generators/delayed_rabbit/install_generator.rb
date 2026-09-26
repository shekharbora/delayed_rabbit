require "rails/generators"

module DelayedRabbit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("install/templates", __dir__)

      def copy_initializer
        copy_file "initializer.rb", "config/initializers/delayed_rabbit.rb"
      end

      def create_rabbitmq_config
        copy_file "rabbitmq.yml", "config/rabbitmq.yml"
      end
    end
  end
end
