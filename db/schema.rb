# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_01_164354) do
  create_table "weather_forecasts", force: :cascade do |t|
    t.string "address", limit: 500, null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.float "current_temperature"
    t.float "high_temperature"
    t.float "low_temperature"
    t.string "condition", limit: 100
    t.integer "humidity"
    t.float "wind_speed"
    t.json "extended_forecast_data"
    t.datetime "forecast_retrieved_at"
    t.datetime "cached_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "headline_data"
    t.index ["address"], name: "index_weather_forecasts_on_address"
    t.index ["cached_until"], name: "index_weather_forecasts_on_cached_until"
    t.index ["created_at"], name: "index_weather_forecasts_on_created_at"
    t.index ["latitude", "longitude"], name: "index_weather_forecasts_on_coordinates"
  end
end
