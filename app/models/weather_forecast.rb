class WeatherForecast < ApplicationRecord
  # Validations
  validates :address, presence: true, length: { minimum: 3, maximum: 500 }
  validates :latitude, presence: true, 
            numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true,
            numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :current_temperature, :high_temperature, :low_temperature, :wind_speed,
            numericality: true, allow_nil: true
  validates :humidity, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true
  
  # Scopes for common queries
  scope :recent, -> { where('created_at >= ?', 1.hour.ago) }
  scope :cached_and_valid, -> { where('cached_until > ?', Time.current) }
  scope :for_coordinates, ->(lat, lng, tolerance = 0.01) {
    where(
      latitude: (lat - tolerance)..(lat + tolerance),
      longitude: (lng - tolerance)..(lng + tolerance)
    )
  }
  scope :for_address, ->(address) { where(address: address) }
  
  # Serialize forecast data as JSON
  # serialize :extended_forecast_data, JSON
  # serialize :headline_data, JSON
  
  # Class method to find or create forecast for coordinates
  def self.find_or_fetch_for_coordinates(latitude, longitude, address = nil)
    # Look for existing valid cached forecast
    existing = for_coordinates(latitude, longitude).cached_and_valid.first
    return existing if existing
    
    # If no valid cache, we'll need to fetch new data
    nil
  end
  
  # Class method to find or create forecast for address
  def self.find_or_fetch_for_address(address)
    # Look for existing valid cached forecast
    existing = for_address(address).cached_and_valid.first
    return existing if existing
    
    # If no valid cache, we'll need to fetch new data
    nil
  end
  
  # Factory method to create from AccuWeather API response
  def self.from_accuweather_response(forecast_data, coordinates = nil)
    return nil unless forecast_data && forecast_data[:daily_forecasts]&.any?
    
    # Get today's forecast for current conditions
    today_forecast = forecast_data[:daily_forecasts].first
    
    # Extract coordinates if provided, otherwise try to get from geocoding
    if coordinates
      latitude = coordinates[:lat]
      longitude = coordinates[:lng]
    else
      # Try to geocode the address to get coordinates
      geocoding_service = GeocodingService.new
      coords = geocoding_service.geocode(forecast_data[:location])
      latitude = coords[:lat] if coords
      longitude = coords[:lng] if coords
    end
    
    create!(
      address: forecast_data[:location],
      latitude: latitude,
      longitude: longitude,
      current_temperature: today_forecast[:temperature][:max], # Use max temp as "current" for daily forecast
      high_temperature: today_forecast[:temperature][:max],
      low_temperature: today_forecast[:temperature][:min],
      condition: today_forecast[:day][:icon_phrase],
      humidity: nil, # AccuWeather daily forecast doesn't include humidity
      wind_speed: nil, # AccuWeather daily forecast doesn't include wind speed
      extended_forecast_data: extract_extended_forecast(forecast_data[:daily_forecasts]),
      headline_data: forecast_data[:headline],
      forecast_retrieved_at: forecast_data[:updated_at] || Time.current,
      cached_until: 30.minutes.from_now
    )
  end
  
  # Check if forecast is still valid (not expired)
  def valid_cache?
    cached_until && cached_until > Time.current
  end
  
  # Temperature formatting utilities
  def formatted_current_temperature
    return 'N/A' unless current_temperature
    "#{current_temperature.round(1)}°F"
  end
  
  def formatted_high_low
    return 'N/A' unless high_temperature && low_temperature
    "H: #{high_temperature.round}°F / L: #{low_temperature.round}°F"
  end
  
  # Get extended forecast as array
  def extended_forecast
    extended_forecast_data || []
  end
  
  # Get headline information
  def headline
    headline_data || {}
  end
  
  # Get headline text
  def headline_text
    # headline_data&.dig('text') || 'No weather alerts'
  end
  
  # Check if there's a weather alert
  def has_weather_alert?
    headline_data && headline_data['severity'] && headline_data['severity'] > 3
  end
  
  # Get today's conditions
  def todays_conditions
    return {} unless extended_forecast.any?
    extended_forecast.first
  end
  
  # Get precipitation info for today
  def todays_precipitation
    conditions = todays_conditions
    return 'No precipitation expected' unless conditions[:day_has_precipitation]
    
    intensity = conditions[:day_precipitation_intensity] || 'Light'
    type = conditions[:day_precipitation_type] || 'Rain'
    "#{intensity} #{type.downcase} expected"
  end
  
  # Temperature unit (always Fahrenheit for AccuWeather in this setup)
  def temperature_unit
    'F'
  end
  
  private
  
  def self.extract_extended_forecast(daily_forecasts)
    return [] unless daily_forecasts.is_a?(Array)
    
    daily_forecasts.map do |day|
      {
        date: day[:date],
        epoch_date: day[:epoch_date],
        high: day[:temperature][:max],
        low: day[:temperature][:min],
        temperature_unit: day[:temperature][:unit],
        day_condition: day[:day][:icon_phrase],
        day_icon: day[:day][:icon],
        day_has_precipitation: day[:day][:has_precipitation],
        day_precipitation_type: day[:day][:precipitation_type],
        day_precipitation_intensity: day[:day][:precipitation_intensity],
        night_condition: day[:night][:icon_phrase],
        night_icon: day[:night][:icon],
        night_has_precipitation: day[:night][:has_precipitation],
        night_precipitation_type: day[:night][:precipitation_type],
        night_precipitation_intensity: day[:night][:precipitation_intensity],
        mobile_link: day[:mobile_link],
        link: day[:link]
      }
    end
  end
end