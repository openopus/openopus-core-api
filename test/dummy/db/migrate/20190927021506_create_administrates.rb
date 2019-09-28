class CreateAdministrates < ActiveRecord::Migration[5.2]
  def change
    create_table :administrates do |t|
      t.references :administrator, foreign_key: { to_table: :users }
      t.references :recipient, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
