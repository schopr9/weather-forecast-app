require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module WeatherForecastApp
  class Application < Rails::Application
    config.load_defaults 7.0
    
    # Enterprise-level configuration
    config.time_zone = 'UTC'
    config.active_record.default_timezone = :utc
    
    # Security configurations
    config.force_ssl = Rails.env.production?
    
    # Logging configuration for production monitoring
    if Rails.env.production?
      config.log_level = :info
      config.logger = ActiveSupport::Logger.new(STDOUT)
    end
    
    # Cache store configuration
    config.cache_store = :redis_cache_store, {
      url: ENV['REDIS_URL'] || 'redis://localhost:6379/0',
      expires_in: 30.minutes,
      race_condition_ttl: 10.seconds
    }
    
    # API rate limiting and timeout configurations
    config.api_timeout = 15.seconds
    config.cache_duration = 30.minutes
  end
end
