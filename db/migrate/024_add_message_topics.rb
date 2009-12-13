class AddMessageTopics < ActiveRecord::Migration
  def self.up
    create_table :message_topics do |t|
      t.references  :message
      t.references  :topic,  :polymorphic => true    # e.g. appointments, waitlist
      t.string      :tag, :length => 50
    end

    add_index :message_topics, :message_id
    add_index :message_topics, [:topic_id, :topic_type]
  end

  def self.down
    drop_table :message_topics
  end
end
