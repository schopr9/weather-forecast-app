# Weather Forecast Application

A production-ready Ruby on Rails weather forecasting application with intelligent caching, geocoding, and enterprise-grade architecture.

## 🌟 Features

- **Address-based Weather Lookup**: Enter any address to get current weather conditions
- **7-Day Extended Forecast**: Comprehensive weather outlook with daily high/low temperatures
- **Intelligent Caching**: 30-minute cache duration with visual indicators for cached results
- **Geocoding Integration**: Converts addresses to coordinates for accurate weather data
- **Enterprise Architecture**: Service objects, comprehensive error handling, and production-ready code
- **Responsive Design**: Modern, mobile-friendly user interface
- **Comprehensive Testing**: Full RSpec test suite with service and controller specs

## 🏗️ Architecture Overview

### Service Layer Architecture
- **WeatherForecastService**: Handles weather API integration with intelligent caching
- **GeocodingService**: Converts addresses to geographic coordinates
- **ApplicationService**: Base service class providing common functionality

### Caching Strategy
- **Geographic Coordinate Caching**: Results cached by rounded lat/lng coordinates
- **30-minute Cache Duration**: Balances data freshness with API efficiency
- **Cache Indicators**: Visual feedback when displaying cached vs. fresh data
- **Redis Integration**: Production-ready caching with Redis backend

### Error Handling
- **Graceful API Failures**: User-friendly error messages for API timeouts
- **Input Validation**: Address validation and sanitization
- **Logging Integration**: Comprehensive logging for debugging and monitoring

## 🚀 Installation & Setup

### Prerequisites
- Ruby 3.1.0+
- Rails 7.0+
- Redis (for caching)
- Weather API Key from [WeatherAPI.com](https://weatherapi.com)

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd weather-forecast-app
   ```

2. **Install dependencies**
   ```bash
   bundle install
   yarn install
   ```

3. **Environment Configuration**
   ```bash
   # Create .env file
   echo "WEATHER_API_KEY=your_api_key_here" > .env
   ```

4. **Database Setup**
   ```bash
   rails db:create
   rails db:migrate
   ```

5. **Start Redis** (if running locally)
   ```bash
   redis-server
   ```

6. **Start the application**
   ```bash
   rails server
   ```

7. **Run tests**
   ```bash
   bundle exec rspec
   ```

### Production Deployment with Docker

1. **Build and run with Docker Compose**
   ```bash
   WEATHER_API_KEY=your_api_key docker-compose up -d
   ```

2. **Environment Variables for Production**
   ```bash
   WEATHER_API_KEY=your_weatherapi_key
   REDIS_URL=redis://localhost:6379/0
   RAILS_ENV=production
   ```

## 🧪 Testing

### Running Tests
```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/services/weather_forecast_service_spec.rb
bundle exec rspec spec/controllers/weather_forecasts_controller_spec.rb

# Run with coverage
bundle exec rspec --format documentation
```

### Test Coverage
- **Service Layer**: Complete unit tests for weather and geocoding services
- **Controller Layer**: Integration tests for all endpoints
- **Model Layer**: Validation and factory method tests
- **Error Handling**: Tests for API failures and edge cases

## 📝 API Integration

### Weather API (WeatherAPI.com)
- **Current Weather**: Temperature, conditions, humidity, wind speed
- **7-Day Forecast**: Daily high/low temperatures and conditions
- **Geocoding**: Address to coordinate conversion

### Rate Limiting & Caching
- **Intelligent Caching**: Reduces API calls through geographic coordinate caching
- **30-minute Cache Duration**: Configurable cache expiration
- **Cache Miss Handling**: Graceful fallback when cache is empty

## 🏢 Enterprise Features

### Production Readiness
- **Docker Support**: Multi-stage builds with Alpine Linux
- **Health Checks**: Application health monitoring endpoints
- **Security Headers**: HTTPS enforcement and security configurations
- **Error Monitoring**: Ready for integration with Sentry/Bugsnag
- **Logging**: Structured logging for production debugging

### Scalability Considerations
- **Service Objects**: Modular, testable business logic
- **Caching Strategy**: Reduces external API dependencies
- **Database Optimization**: Efficient queries and indexing ready
- **Load Balancer Ready**: Stateless application design

### Code Quality
- **Naming Conventions**: Enterprise-standard naming throughout
- **Documentation**: Comprehensive inline documentation
- **Design Patterns**: Service objects, factory methods, decorators
- **Error Encapsulation**: Proper exception handling and user feedback

## 🔧 Configuration

### Environment Variables
```bash
# Required
WEATHER_API_KEY=your_weatherapi_key

# Optional (with defaults)
REDIS_URL=redis://localhost:6379/0
WEATHER_API_TIMEOUT=15
WEATHER_API_RETRY_ATTEMPTS=3
CACHE_DURATION_MINUTES=30
```

### Custom Configuration
The application supports extensive customization through environment variables and initializers:

- **API Timeouts**: Configurable request timeouts
- **Cache Duration**: Adjustable cache expiration
- **Retry Logic**: Configurable API retry attempts
- **Security Settings**: HTTPS enforcement and headers

## 📊 Performance Optimizations

### Caching Strategy
- **Geographic Coordinate Rounding**: Reduces cache fragmentation
- **Redis Integration**: Fast, distributed caching
- **Cache Indicators**: User feedback for cache hits

### API Efficiency
- **Batch Geocoding**: Efficient address-to-coordinate conversion
- **Request Deduplication**: Prevents duplicate API calls
- **Timeout Handling**: Graceful handling of slow API responses

## 🚦 Usage Examples

### Basic Weather Lookup
1. Navigate to the application homepage
2. Enter any address (e.g., "123 Main St, New York, NY")
3. Click "Get Weather Forecast"
4. View current conditions and 7-day forecast

### API Testing
```bash
# Test API connectivity
rails weather:test_api

# Clear cache
rails weather:clear_cache

# Generate test data (development only)
rails weather:generate_test_data
```

## 🤝 Contributing

This codebase follows enterprise development standards:

1. **Code Style**: Follow Rails conventions and Rubocop guidelines
2. **Testing**: Maintain >90% test coverage
3. **Documentation**: Update README and inline docs for changes
4. **Security**: Never commit API keys or sensitive data

## 📄 License

This project is built for educational and demonstration purposes. Ensure you have proper licensing for any production use of weather APIs.

---

**Built with enterprise-grade practices for production deployment. Features comprehensive caching, error handling, testing, and scalability considerations.**