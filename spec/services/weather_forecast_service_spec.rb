require 'rails_helper'

RSpec.describe WeatherForecastService, type: :service do
  let(:service) { described_class.new }
  let(:api_key) { 'test_api_key' }
  let(:address) { 'New York, NY' }
  let(:location_key) { '349727' }
  
  before do
    allow(ENV).to receive(:[]).with('WEATHER_API_KEY').and_return(api_key)
    Rails.cache.clear
  end

  describe '#initialize' do
    it 'sets up the cache store' do
      expect(service.instance_variable_get(:@cache_store)).to eq(Rails.cache)
    end
  end

  describe '#get_weather_forecast' do
    context 'with valid address' do
      let(:location_response) do
        [
          {
            'Key' => location_key,
            'LocalizedName' => 'New York',
            'GeoPosition' => {
              'Latitude' => 40.7589,
              'Longitude' => -73.9851
            },
            'AdministrativeArea' => {
              'LocalizedName' => 'New York'
            },
            'Country' => {
              'LocalizedName' => 'United States'
            }
          }
        ]
      end

      let(:forecast_response) do
        {
          'Headline' => {
            'Text' => 'Pleasant weather expected',
            'Category' => 'mild',
            'Severity' => 3,
            'EffectiveDate' => '2025-08-04T07:00:00-04:00',
            'EndDate' => '2025-08-05T07:00:00-04:00'
          },
          'DailyForecasts' => [
            {
              'Date' => '2025-08-04T07:00:00-04:00',
              'EpochDate' => 1722772800,
              'Temperature' => {
                'Minimum' => { 'Value' => 65.0, 'Unit' => 'F' },
                'Maximum' => { 'Value' => 78.0, 'Unit' => 'F' }
              },
              'Day' => {
                'Icon' => 1,
                'IconPhrase' => 'Sunny',
                'HasPrecipitation' => false,
                'PrecipitationType' => nil,
                'PrecipitationIntensity' => nil
              },
              'Night' => {
                'Icon' => 33,
                'IconPhrase' => 'Clear',
                'HasPrecipitation' => false,
                'PrecipitationType' => nil,
                'PrecipitationIntensity' => nil
              },
              'MobileLink' => 'http://mobile.accuweather.com/forecast',
              'Link' => 'http://www.accuweather.com/forecast'
            }
          ]
        }
      end

      before do
        # Mock location lookup
        allow(described_class).to receive(:get)
          .with("#{described_class::BASE_URL}/locations/v1/search", any_args)
          .and_return(double(success?: true, parsed_response: location_response))

        # Mock forecast lookup
        allow(described_class).to receive(:get)
          .with("#{described_class::BASE_URL}/forecasts/v1/daily/5day/#{location_key}", any_args)
          .and_return(double(success?: true, parsed_response: forecast_response))
      end

      it 'returns weather forecast data' do
        result = service.get_weather_forecast(address)
        
        expect(result).to be_a(Hash)
        expect(result[:location]).to eq(address)
        expect(result[:headline]).to be_present
        expect(result[:daily_forecasts]).to be_an(Array)
        expect(result[:updated_at]).to be_present
      end

      it 'returns properly structured headline data' do
        result = service.get_weather_forecast(address)
        headline = result[:headline]
        
        expect(headline[:text]).to eq('Pleasant weather expected')
        expect(headline[:category]).to eq('mild')
        expect(headline[:severity]).to eq(3)
        expect(headline[:effective_date]).to eq('2025-08-04T07:00:00-04:00')
        expect(headline[:end_date]).to eq('2025-08-05T07:00:00-04:00')
      end

      it 'returns properly structured daily forecast data' do
        result = service.get_weather_forecast(address)
        forecast = result[:daily_forecasts].first
        
        expect(forecast[:date]).to eq('2025-08-04T07:00:00-04:00')
        expect(forecast[:epoch_date]).to eq(1722772800)
        expect(forecast[:temperature][:min]).to eq(65.0)
        expect(forecast[:temperature][:max]).to eq(78.0)
        expect(forecast[:temperature][:unit]).to eq('F')
        expect(forecast[:day][:icon_phrase]).to eq('Sunny')
        expect(forecast[:night][:icon_phrase]).to eq('Clear')
        expect(forecast[:mobile_link]).to be_present
        expect(forecast[:link]).to be_present
      end

      it 'caches the result for 30 minutes' do
        expect(Rails.cache).to receive(:write)
          .with(anything, anything, expires_in: 30.minutes)
        
        service.get_weather_forecast(address)
      end

      it 'returns cached result if available' do
        cached_data = { location: address, cached: true }
        allow(Rails.cache).to receive(:read).and_return(cached_data)
        
        result = service.get_weather_forecast(address)
        expect(result).to eq(cached_data)
      end
    end

    context 'with blank address' do
      it 'returns nil for blank address' do
        expect(service.get_weather_forecast('')).to be_nil
        expect(service.get_weather_forecast(nil)).to be_nil
        expect(service.get_weather_forecast('   ')).to be_nil
      end
    end

    context 'when location lookup fails' do
      before do
        allow(described_class).to receive(:get)
          .with("#{described_class::BASE_URL}/locations/v1/search", any_args)
          .and_return(double(success?: true, parsed_response: []))
      end

      it 'returns nil when no location found' do
        result = service.get_weather_forecast(address)
        expect(result).to be_nil
      end
    end

    context 'when forecast lookup fails' do
      before do
        # Mock successful location lookup
        allow(described_class).to receive(:get)
          .with("#{described_class::BASE_URL}/locations/v1/search", any_args)
          .and_return(double(success?: true, parsed_response: [{ 'Key' => location_key }]))

        # Mock failed forecast lookup
        allow(described_class).to receive(:get)
          .with("#{described_class::BASE_URL}/forecasts/v1/daily/5day/#{location_key}", any_args)
          .and_return(double(success?: false, parsed_response: nil))
      end

      it 'returns nil when forecast lookup fails' do
        result = service.get_weather_forecast(address)
        expect(result).to be_nil
      end
    end

    context 'when API request raises an error' do
      before do
        allow(described_class).to receive(:get).and_raise(HTTParty::Error.new('API Error'))
      end

      it 'raises WeatherError' do
        expect { service.get_weather_forecast(address) }
          .to raise_error(WeatherForecastService::WeatherError, 'Unable to get weather forecast')
      end
    end
  end

  describe '#geocode' do
    let(:location_response) do
      [
        {
          'Key' => location_key,
          'LocalizedName' => 'New York',
          'GeoPosition' => {
            'Latitude' => 40.7589,
            'Longitude' => -73.9851
          },
          'AdministrativeArea' => {
            'LocalizedName' => 'New York'
          },
          'Country' => {
            'LocalizedName' => 'United States'
          }
        }
      ]
    end

    before do
      allow(described_class).to receive(:get)
        .with("#{described_class::BASE_URL}/locations/v1/search", any_args)
        .and_return(double(success?: true, parsed_response: location_response))
    end

    it 'returns geocoded location data' do
      result = service.geocode(address)
      
      expect(result).to be_a(Hash)
      expect(result[:lat]).to eq(40.7589)
      expect(result[:lng]).to eq(-73.9851)
      expect(result[:name]).to eq('New York')
      expect(result[:region]).to eq('New York')
      expect(result[:country]).to eq('United States')
    end

    it 'returns nil when location not found' do
      allow(described_class).to receive(:get)
        .and_return(double(success?: true, parsed_response: []))
      
      result = service.geocode(address)
      expect(result).to be_nil
    end
  end

  describe 'private methods' do
    describe '#generate_weather_cache_key' do
      it 'generates consistent cache key for same address' do
        key1 = service.send(:generate_weather_cache_key, 'New York, NY')
        key2 = service.send(:generate_weather_cache_key, 'New York, NY')
        
        expect(key1).to eq(key2)
        expect(key1).to start_with('weather_forecast:')
      end

      it 'generates different cache keys for different addresses' do
        key1 = service.send(:generate_weather_cache_key, 'New York, NY')
        key2 = service.send(:generate_weather_cache_key, 'Los Angeles, CA')
        
        expect(key1).not_to eq(key2)
      end

      it 'normalizes address case and whitespace' do
        key1 = service.send(:generate_weather_cache_key, 'New York, NY')
        key2 = service.send(:generate_weather_cache_key, '  NEW YORK, NY  ')
        
        expect(key1).to eq(key2)
      end
    end

    describe '#parse_headline' do
      it 'parses headline data correctly' do
        headline_data = {
          'Text' => 'Pleasant weather',
          'Category' => 'mild',
          'Severity' => 2,
          'EffectiveDate' => '2025-08-04T07:00:00-04:00',
          'EndDate' => '2025-08-05T07:00:00-04:00'
        }
        
        result = service.send(:parse_headline, headline_data)
        
        expect(result[:text]).to eq('Pleasant weather')
        expect(result[:category]).to eq('mild')
        expect(result[:severity]).to eq(2)
        expect(result[:effective_date]).to eq('2025-08-04T07:00:00-04:00')
        expect(result[:end_date]).to eq('2025-08-05T07:00:00-04:00')
      end

      it 'returns nil for nil input' do
        result = service.send(:parse_headline, nil)
        expect(result).to be_nil
      end
    end

    describe '#parse_daily_forecasts' do
      let(:daily_forecast_data) do
        [
          {
            'Date' => '2025-08-04T07:00:00-04:00',
            'EpochDate' => 1722772800,
            'Temperature' => {
              'Minimum' => { 'Value' => 65.0, 'Unit' => 'F' },
              'Maximum' => { 'Value' => 78.0, 'Unit' => 'F' }
            },
            'Day' => {
              'Icon' => 1,
              'IconPhrase' => 'Sunny',
              'HasPrecipitation' => true,
              'PrecipitationType' => 'Rain',
              'PrecipitationIntensity' => 'Light'
            },
            'Night' => {
              'Icon' => 33,
              'IconPhrase' => 'Clear',
              'HasPrecipitation' => false,
              'PrecipitationType' => nil,
              'PrecipitationIntensity' => nil
            },
            'MobileLink' => 'http://mobile.accuweather.com',
            'Link' => 'http://www.accuweather.com'
          }
        ]
      end

      it 'parses daily forecast data correctly' do
        result = service.send(:parse_daily_forecasts, daily_forecast_data)
        forecast = result.first
        
        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
        
        expect(forecast[:date]).to eq('2025-08-04T07:00:00-04:00')
        expect(forecast[:epoch_date]).to eq(1722772800)
        expect(forecast[:temperature][:min]).to eq(65.0)
        expect(forecast[:temperature][:max]).to eq(78.0)
        expect(forecast[:temperature][:unit]).to eq('F')
        
        expect(forecast[:day][:icon]).to eq(1)
        expect(forecast[:day][:icon_phrase]).to eq('Sunny')
        expect(forecast[:day][:has_precipitation]).to be true
        expect(forecast[:day][:precipitation_type]).to eq('Rain')
        expect(forecast[:day][:precipitation_intensity]).to eq('Light')
        
        expect(forecast[:night][:icon]).to eq(33)
        expect(forecast[:night][:icon_phrase]).to eq('Clear')
        expect(forecast[:night][:has_precipitation]).to be false
        
        expect(forecast[:mobile_link]).to eq('http://mobile.accuweather.com')
        expect(forecast[:link]).to eq('http://www.accuweather.com')
      end

      it 'returns empty array for nil input' do
        result = service.send(:parse_daily_forecasts, nil)
        expect(result).to eq([])
      end

      it 'returns empty array for non-array input' do
        result = service.send(:parse_daily_forecasts, 'not an array')
        expect(result).to eq([])
      end
    end
  end

  describe 'error handling and logging' do
    it 'logs info messages for successful operations' do
      allow(described_class).to receive(:get).and_return(
        double(success?: true, parsed_response: [{ 'Key' => location_key }]),
        double(success?: true, parsed_response: { 'DailyForecasts' => [] })
      )
      
      expect(service).to receive(:log_info).at_least(:once)
      service.get_weather_forecast(address)
    end

    it 'logs error messages for failed operations' do
      allow(described_class).to receive(:get).and_return(
        double(success?: true, parsed_response: [])
      )
      
      expect(service).to receive(:log_error).at_least(:once)
      service.get_weather_forecast(address)
    end
  end

  describe 'API configuration' do
    it 'uses correct API endpoints' do
      expect(described_class::BASE_URL).to eq('http://dataservice.accuweather.com')
    end
  end
end