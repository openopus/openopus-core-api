class CreateEmployments < ActiveRecord::Migration[5.2]
  def change
    create_table :employments do |t|
      t.references :organization, foreign_key: true
      t.references :user, foreign_key: true
      t.string :job_title

      t.timestamps
    end
  end
end
