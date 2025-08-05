class WeatherForecastService < ApplicationService
  include HTTParty
  
  API_KEY = Rails.application.config.weather_api_key || 'mPkNtDtsBEdIO4uByPD9FkN7WajugW0r'
  BASE_URL = 'http://dataservice.accuweather.com'
  
  class WeatherForecastError < StandardError; end
  class WeatherError < StandardError; end
  
  def initialize
    @cache_store = Rails.cache
  end
  
  # Main method to get weather forecast for an address
  # First geocodes to get location key, then fetches weather
  def get_weather_forecast(address)
    return nil if address.blank?
    
    cache_key = generate_weather_cache_key(address)
    
    # Check cache first (30 minute expiration)
    cached_result = @cache_store.read(cache_key)
    return cached_result if cached_result
    
    log_info("Getting weather forecast for address: #{address}")
    
    # Step 1: Get location key from address
    location_key = get_location_key(address)
    return nil unless location_key
    
    # Step 2: Get weather forecast using location key
    forecast_data = get_forecast(location_key, address)
    
    # Cache successful results for 30 minutes
    if forecast_data
      @cache_store.write(cache_key, forecast_data, expires_in: 30.minutes)
    end
    
    forecast_data
    
  rescue HTTParty::Error, Net::TimeoutError => e
    log_error("Weather API error for address '#{address}': #{e.message}", e)
    raise WeatherError, "Unable to get weather forecast"
  end
  
  # Legacy geocoding method for backward compatibility
  def geocode(address)
    location_data = get_location_key(address, include_details: true)
    return nil unless location_data
    
    # Return coordinates format for backward compatibility
    {
      lat: location_data[:lat],
      lng: location_data[:lng],
      name: location_data[:name],
      region: location_data[:region],
      country: location_data[:country]
    }
  end
  
  private
  
  def get_location_key(address, include_details: false)
    log_info("Getting location key for address: #{address}")
    
    response = self.class.get(
      "#{BASE_URL}/locations/v1/search",
      query: {
        apikey: API_KEY,
        q: address,
        details: include_details
      },
      timeout: 10
    )
    
    handle_location_response(response, address, include_details)
  end
  
  def get_forecast(location_key, address)
    log_info("Getting forecast for location key: #{location_key}")
    
    response = self.class.get(
      "#{BASE_URL}/forecasts/v1/daily/5day/#{location_key}",
      query: {
        apikey: API_KEY,
        details: true,
        metric: false # Set to true if you want Celsius
      },
      timeout: 10
    )
    
    handle_forecast_response(response, address)
  end
  
  def handle_location_response(response, address, include_details)
    if response.success? && response.parsed_response.is_a?(Array) && response.parsed_response.any?
      location = response.parsed_response.first
      
      if include_details
        # Return full location details for geocoding
        {
          location_key: location['Key'],
          lat: location.dig('GeoPosition', 'Latitude'),
          lng: location.dig('GeoPosition', 'Longitude'),
          name: location['LocalizedName'],
          region: location.dig('AdministrativeArea', 'LocalizedName'),
          country: location.dig('Country', 'LocalizedName')
        }
      else
        # Return just location key for weather lookup
        location['Key']
      end
    else
      log_error("Failed to get location key for address '#{address}': No results found")
      nil
    end
  end
  
  def handle_forecast_response(response, address)
    if response.success? && response.parsed_response.is_a?(Hash)
      forecast_data = response.parsed_response
      
      # Parse and structure the forecast data
      parsed_forecast = {
        headline: parse_headline(forecast_data['Headline']),
        daily_forecasts: parse_daily_forecasts(forecast_data['DailyForecasts']),
        location: address,
        updated_at: Time.current
      }
      
      log_info("Successfully retrieved weather forecast for '#{address}'")
      parsed_forecast
    else
      log_error("Failed to get weather forecast for address '#{address}': Invalid response")
      nil
    end
  end
  
  def parse_headline(headline_data)
    return nil unless headline_data
    
    {
      text: headline_data['Text'],
      category: headline_data['Category'],
      severity: headline_data['Severity'],
      effective_date: headline_data['EffectiveDate'],
      end_date: headline_data['EndDate']
    }
  end
  
  def parse_daily_forecasts(daily_forecasts_data)
    return [] unless daily_forecasts_data.is_a?(Array)
    
    daily_forecasts_data.map do |day_data|
      {
        date: day_data['Date'],
        epoch_date: day_data['EpochDate'],
        temperature: {
          min: day_data.dig('Temperature', 'Minimum', 'Value'),
          max: day_data.dig('Temperature', 'Maximum', 'Value'),
          unit: day_data.dig('Temperature', 'Minimum', 'Unit')
        },
        day: {
          icon: day_data.dig('Day', 'Icon'),
          icon_phrase: day_data.dig('Day', 'IconPhrase'),
          has_precipitation: day_data.dig('Day', 'HasPrecipitation'),
          precipitation_type: day_data.dig('Day', 'PrecipitationType'),
          precipitation_intensity: day_data.dig('Day', 'PrecipitationIntensity')
        },
        night: {
          icon: day_data.dig('Night', 'Icon'),
          icon_phrase: day_data.dig('Night', 'IconPhrase'),
          has_precipitation: day_data.dig('Night', 'HasPrecipitation'),
          precipitation_type: day_data.dig('Night', 'PrecipitationType'),
          precipitation_intensity: day_data.dig('Night', 'PrecipitationIntensity')
        },
        mobile_link: day_data['MobileLink'],
        link: day_data['Link']
      }
    end
  end
  
  def generate_weather_cache_key(address)
    "weather_forecast:#{Digest::MD5.hexdigest(address.downcase.strip)}"
  end
  
  def generate_geocoding_cache_key(address)
    "geocoding:#{Digest::MD5.hexdigest(address.downcase.strip)}"
  end
end