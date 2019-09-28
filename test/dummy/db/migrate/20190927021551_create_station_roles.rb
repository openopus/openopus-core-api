class CreateStationRoles < ActiveRecord::Migration[5.2]
  def change
    create_table :station_roles do |t|
      t.references :user, foreign_key: true
      t.references :station, foreign_key: true
      t.string :job_title

      t.timestamps
    end
  end
end
