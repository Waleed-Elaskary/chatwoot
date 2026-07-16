class CreateConversationReadStates < ActiveRecord::Migration[7.1]
  # Per-agent read tracking: one row per (user, conversation) an agent has opened.
  # `last_seen_at` is that agent's personal cutoff for "unread" (an incoming message
  # created after it is unread FOR THAT AGENT). Absence of a row means the agent has
  # never opened the conversation, so it is unread for them.
  def change
    create_table :conversation_read_states do |t|
      t.references :account, null: false, index: true
      t.references :conversation, null: false, index: true
      t.references :user, null: false, index: false
      t.datetime :last_seen_at, precision: nil

      t.timestamps
    end

    add_index :conversation_read_states, [:user_id, :conversation_id],
              unique: true,
              name: 'index_conversation_read_states_on_user_and_conversation'
  end
end
