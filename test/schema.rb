ActiveRecord::Schema.define(:version => 1) do
  create_table :messages, :force => true do |t|
    t.column :message_content, :string
    t.column :state, :string
    t.column :processing_attempt_count, :integer, :default => 0
    t.column :processing_started_at, :datetime
    t.column :completed_at, :datetime
    t.column :failure_count, :integer, :default => 0
    t.column :failed_at, :datetime
    t.column :last_exception, :text
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end
  
end
