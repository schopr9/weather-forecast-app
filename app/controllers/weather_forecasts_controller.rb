class WeatherForecastsController < ApplicationController
  def index
    # Just show the search form initially
    @weather_forecast = nil
    @from_cache = false
  end
  
  def search
    address = params[:address]&.strip
    
    if address.blank?
      flash.now[:alert] = 'Please enter a valid address'
      @weather_forecast = nil
      @from_cache = false
      @forecast_data = nil
      render :index
      return
    end
    
    begin
      # Check for cached forecast first
      cached_forecast = WeatherForecast.find_or_fetch_for_address(address)
      
      if cached_forecast
        @weather_forecast = cached_forecast
        @from_cache = true
        @forecast_data = cached_forecast.extended_forecast_data
      else
        # Fetch new weather data
        @weather_forecast = fetch_weather_forecast(address)
        @from_cache = false
        @forecast_data = @weather_forecast.extended_forecast_data
      end
      
      if @weather_forecast
        flash.now[:success] = @from_cache ? 'Weather data loaded from cache' : 'Fresh weather data retrieved'
        render :index
      else
        flash.now[:alert] = 'Unable to retrieve weather data for the specified address. Please try again.'
        @weather_forecast = nil
        @from_cache = false
        @forecast_data = nil
        render :index
      end
      
    rescue WeatherForecastService::WeatherError => e
      Rails.logger.error "Weather API error: #{e.message}"
      flash.now[:alert] = 'Weather service is currently unavailable. Please try again later.'
      @weather_forecast = nil
      @from_cache = false
      @forecast_data = nil
      render :index
    rescue StandardError => e
      Rails.logger.error "Unexpected error in weather search: #{e.message}\n#{e.backtrace.join("\n")}"
      flash.now[:alert] = 'An unexpected error occurred. Please try again.'
      @weather_forecast = nil
      @from_cache = false
      @forecast_data = nil
      render :index
    end
  end
  
  def show
    @weather_forecast = WeatherForecast.find(params[:id])
    @from_cache = true
    
    unless @weather_forecast.valid_cache?
      # Try to refresh expired forecast
      begin
        refreshed_forecast = fetch_weather_forecast(@weather_forecast.address)
        if refreshed_forecast
          @weather_forecast = refreshed_forecast
          @from_cache = false
        end
      rescue StandardError => e
        Rails.logger.error "Failed to refresh weather forecast: #{e.message}"
        # Keep using the stale data
      end
    end
    
  rescue ActiveRecord::RecordNotFound
    redirect_to weather_forecasts_path, alert: 'Weather forecast not found.'
  end
  
  private
  
  def fetch_weather_forecast(address)
    weather_forecast_service = WeatherForecastService.new
    
    # Get weather forecast data from AccuWeather
    forecast_data = weather_forecast_service.get_weather_forecast(address)
    return nil unless forecast_data
    
    # Also get coordinates for the address
    coordinates = weather_forecast_service.geocode(address)
    
    # Create and return the weather forecast record
    WeatherForecast.from_accuweather_response(forecast_data, coordinates)
  end
end