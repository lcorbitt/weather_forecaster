class CreateLocations < ActiveRecord::Migration[8.0]
  def up
    create_table :locations do |t|
      t.string :address, null: false
      t.decimal :latitude
      t.decimal :longitude
      t.string :zip_code, null: false

      t.timestamps
    end

    add_index :locations, :zip_code, unique: true

    # Extract ZIP codes from addresses and clean up invalid entries
    execute <<-SQL
      UPDATE locations 
      SET zip_code = (
        CASE 
          WHEN address ~ '\\d{5}(-\\d{4})?' 
          THEN substring(address from '\\d{5}(-\\d{4})?')
          ELSE NULL 
        END
      )
    SQL

    execute "DELETE FROM locations WHERE zip_code IS NULL"
  end

  def down
    drop_table :locations
  end
end
