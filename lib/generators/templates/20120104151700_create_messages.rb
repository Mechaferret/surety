class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.string :message_content
      t.string :state
      t.integer :processing_attempt_count, :default => 0
      t.datetime :processing_started_at
      t.datetime :completed_at
      t.integer :failure_count, :default => 0
      t.datetime :failed_at
      t.text :last_exception
      t.timestamps
    end

    add_index :messages, [:state, :failed_at]
  end

  def self.down
    drop_table :messages
  end
end