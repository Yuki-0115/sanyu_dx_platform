# frozen_string_literal: true

require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module WorkerWeb
  class Application < Rails::Application
    config.load_defaults 8.0

    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = "Tokyo"
    config.i18n.default_locale = :ja

    config.generators.system_tests = nil
  end
end
