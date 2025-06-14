class CreateWeatherForecasts < ActiveRecord::Migration[8.0]
  def change
    create_table :weather_forecasts do |t|
      t.references :location, null: false, foreign_key: true
      t.decimal :current_temp
      t.decimal :high_temp
      t.decimal :low_temp
      t.string :conditions
      t.datetime :cached_at

      t.timestamps
    end
  end
end
