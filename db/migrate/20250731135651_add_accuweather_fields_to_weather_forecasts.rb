class AddAccuweatherFieldsToWeatherForecasts < ActiveRecord::Migration[8.0]
  def change
    add_column :weather_forecasts, :headline_data, :text, null: true
  end
end
