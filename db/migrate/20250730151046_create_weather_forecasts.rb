class CreateWeatherForecasts < ActiveRecord::Migration[8.0]
  def change
    create_table :weather_forecasts do |t|
      t.string :address, null: false, limit: 500
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.float :current_temperature
      t.float :high_temperature
      t.float :low_temperature
      t.string :condition, limit: 100
      t.integer :humidity
      t.float :wind_speed
      t.text :extended_forecast_data # JSON storage for extended forecast
      t.datetime :forecast_retrieved_at
      t.datetime :cached_until
      
      t.timestamps
      
      # Indexes for performance
      t.index [:latitude, :longitude], name: 'index_weather_forecasts_on_coordinates'
      t.index :address
      t.index :cached_until
      t.index :created_at
    end
  end
end
