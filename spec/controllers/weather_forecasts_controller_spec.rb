# spec/controllers/weather_forecasts_controller_spec.rb
require 'rails_helper'

RSpec.describe WeatherForecastsController, type: :controller do
  let(:address) { 'New York, NY' }
  let(:mock_weather_forecast) { double('WeatherForecast', id: 1, address: address, extended_forecast_data: forecast_data) }
  let(:mock_service) { instance_double(WeatherForecastService) }
  let(:forecast_data) do
    [
      {
        'date' => '2025-08-04T07:00:00-04:00',
        'high' => 78.0,
        'low' => 65.0,
        'temperature_unit' => 'F',
        'day_condition' => 'Sunny',
        'night_condition' => 'Clear'
      }
    ]
  end

  before do
    allow(WeatherForecastService).to receive(:new).and_return(mock_service)
  end

  describe 'GET #index' do
    it 'renders the index template' do
      get :index
      
      expect(response).to render_template(:index)
      expect(response).to have_http_status(:ok)
    end

    it 'initializes instance variables' do
      get :index
      
      expect(assigns(:weather_forecast)).to be_nil
      expect(assigns(:from_cache)).to be false
    end
  end

  describe 'GET #search' do
    context 'with blank address' do
      it 'renders index with alert for empty string' do
        get :search, params: { address: '' }
        
        expect(response).to render_template(:index)
        expect(flash.now[:alert]).to eq('Please enter a valid address')
        expect(assigns(:weather_forecast)).to be_nil
        expect(assigns(:from_cache)).to be false
        expect(assigns(:forecast_data)).to be_nil
      end

      it 'renders index with alert for whitespace only' do
        get :search, params: { address: '   ' }
        
        expect(response).to render_template(:index)
        expect(flash.now[:alert]).to eq('Please enter a valid address')
        expect(assigns(:weather_forecast)).to be_nil
        expect(assigns(:from_cache)).to be false
        expect(assigns(:forecast_data)).to be_nil
      end

      it 'renders index with alert for nil address' do
        get :search, params: {}
        
        expect(response).to render_template(:index)
        expect(flash.now[:alert]).to eq('Please enter a valid address')
        expect(assigns(:weather_forecast)).to be_nil
        expect(assigns(:from_cache)).to be false
        expect(assigns(:forecast_data)).to be_nil
      end
    end

    context 'with valid address' do
      context 'when cached forecast exists' do
        before do
          allow(WeatherForecast).to receive(:find_or_fetch_for_address)
            .with(address)
            .and_return(mock_weather_forecast)
        end

        it 'uses cached data and renders index' do
          get :search, params: { address: address }
          
          expect(response).to render_template(:index)
          expect(assigns(:weather_forecast)).to eq(mock_weather_forecast)
          expect(assigns(:from_cache)).to be true
          expect(assigns(:forecast_data)).to eq(forecast_data)
          expect(flash.now[:success]).to eq('Weather data loaded from cache')
        end
      end

      context 'when no cached forecast exists' do
        before do
          allow(WeatherForecast).to receive(:find_or_fetch_for_address)
            .with(address)
            .and_return(nil)
        end

        context 'and fresh data is successfully fetched' do
          let(:coordinates) { { lat: 40.7589, lng: -73.9851 } }
          let(:service_response) do
            {
              headline: { text: 'Pleasant weather' },
              daily_forecasts: [],
              location: address,
              updated_at: Time.current
            }
          end

          before do
            allow(mock_service).to receive(:get_weather_forecast)
              .with(address)
              .and_return(service_response)
            allow(mock_service).to receive(:geocode)
              .with(address)
              .and_return(coordinates)
            allow(WeatherForecast).to receive(:from_accuweather_response)
              .with(service_response, coordinates)
              .and_return(mock_weather_forecast)
          end

          it 'fetches fresh data and renders index' do
            get :search, params: { address: address }
            
            expect(response).to render_template(:index)
            expect(assigns(:weather_forecast)).to eq(mock_weather_forecast)
            expect(assigns(:from_cache)).to be false
            expect(assigns(:forecast_data)).to eq(forecast_data)
            expect(flash.now[:success]).to eq('Fresh weather data retrieved')
          end
        end

        context 'and fresh data fetch fails' do
          before do
            allow(mock_service).to receive(:get_weather_forecast)
              .with(address)
              .and_return(nil)
          end

          it 'renders index with error message' do
            get :search, params: { address: address }
            
            expect(response).to render_template(:index)
            expect(assigns(:weather_forecast)).to be_nil
            expect(assigns(:from_cache)).to be false
            expect(assigns(:forecast_data)).to be_nil
            expect(flash.now[:alert]).to eq('An unexpected error occurred. Please try again.')
          end
        end
      end

      context 'when WeatherForecastService::WeatherError occurs' do
        before do
          allow(WeatherForecast).to receive(:find_or_fetch_for_address)
            .and_raise(WeatherForecastService::WeatherError, 'API Error')
        end

        it 'handles the error gracefully' do
          expect(Rails.logger).to receive(:error).with('Weather API error: API Error')
          
          get :search, params: { address: address }
          
          expect(response).to render_template(:index)
          expect(assigns(:weather_forecast)).to be_nil
          expect(assigns(:from_cache)).to be false
          expect(assigns(:forecast_data)).to be_nil
          expect(flash.now[:alert]).to eq('Weather service is currently unavailable. Please try again later.')
        end
      end

      context 'when StandardError occurs' do
        let(:error_message) { 'Unexpected error' }
        let(:error) { StandardError.new(error_message) }

        before do
          allow(error).to receive(:backtrace).and_return(['line1', 'line2'])
          allow(WeatherForecast).to receive(:find_or_fetch_for_address)
            .and_raise(error)
        end

        it 'handles unexpected errors gracefully' do
          expect(Rails.logger).to receive(:error).with(/Unexpected error in weather search: #{error_message}/)
          
          get :search, params: { address: address }
          
          expect(response).to render_template(:index)
          expect(assigns(:weather_forecast)).to be_nil
          expect(assigns(:from_cache)).to be false
          expect(assigns(:forecast_data)).to be_nil
          expect(flash.now[:alert]).to eq('An unexpected error occurred. Please try again.')
        end
      end
    end
  end

  describe 'private methods' do
    describe '#fetch_weather_forecast' do
      let(:service_response) do
        {
          headline: { text: 'Pleasant weather' },
          daily_forecasts: [],
          location: address,
          updated_at: Time.current
        }
      end
      let(:coordinates) { { lat: 40.7589, lng: -73.9851 } }

      context 'when service returns data' do
        before do
          allow(mock_service).to receive(:get_weather_forecast)
            .with(address)
            .and_return(service_response)
          allow(mock_service).to receive(:geocode)
            .with(address)
            .and_return(coordinates)
          allow(WeatherForecast).to receive(:from_accuweather_response)
            .with(service_response, coordinates)
            .and_return(mock_weather_forecast)
        end

        it 'returns a weather forecast' do
          result = controller.send(:fetch_weather_forecast, address)
          expect(result).to eq(mock_weather_forecast)
        end
      end

      context 'when service returns nil' do
        before do
          allow(mock_service).to receive(:get_weather_forecast)
            .with(address)
            .and_return(nil)
        end

        it 'returns nil' do
          result = controller.send(:fetch_weather_forecast, address)
          expect(result).to be_nil
        end
      end
    end
  end

  describe 'instance variable assignments' do
    context 'successful search' do
      before do
        allow(WeatherForecast).to receive(:find_or_fetch_for_address)
          .with(address)
          .and_return(mock_weather_forecast)
      end

      it 'assigns all expected instance variables' do
        get :search, params: { address: address }
        
        expect(assigns(:weather_forecast)).to eq(mock_weather_forecast)
        expect(assigns(:from_cache)).to eq(true)
        expect(assigns(:forecast_data)).to eq(forecast_data)
      end
    end

    context 'failed search' do
      before do
        allow(WeatherForecast).to receive(:find_or_fetch_for_address)
          .with(address)
          .and_return(nil)
        allow(mock_service).to receive(:get_weather_forecast).and_return(nil)
      end

      it 'assigns nil to all weather-related variables' do
        get :search, params: { address: address }
        
        expect(assigns(:weather_forecast)).to be_nil
        expect(assigns(:from_cache)).to be false
        expect(assigns(:forecast_data)).to be_nil
      end
    end
  end
end