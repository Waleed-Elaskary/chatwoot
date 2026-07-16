class BackfillConversationReadStatesFromAssignee < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  # Seed each assigned conversation's assignee with a per-agent read-state row derived from the
  # existing assignee_last_seen_at, so agents don't see all their assigned conversations light up
  # as "unread" the moment the feature is enabled. Non-assignees populate lazily as they open
  # conversations. Runs regardless of the feature flag so the data is ready before rollout.
  #
  # Lightweight table-scoped models keep the migration replay-safe if the real models change.
  class MigrationConversation < ApplicationRecord
    self.table_name = 'conversations'
  end

  class MigrationReadState < ApplicationRecord
    self.table_name = 'conversation_read_states'
  end

  def up
    MigrationConversation
      .where.not(assignee_id: nil)
      .where.not(assignee_last_seen_at: nil)
      .in_batches(of: 5000) do |batch|
        now = Time.current
        rows = batch.pluck(:account_id, :id, :assignee_id, :assignee_last_seen_at).map do |account_id, conversation_id, user_id, last_seen_at|
          {
            account_id: account_id,
            conversation_id: conversation_id,
            user_id: user_id,
            last_seen_at: last_seen_at,
            created_at: now,
            updated_at: now
          }
        end
        # ON CONFLICT DO NOTHING via the unique (user_id, conversation_id) index — idempotent and
        # never clobbers a row an agent has already created organically.
        MigrationReadState.insert_all(rows, unique_by: %i[user_id conversation_id]) if rows.any?
      end
  end

  def down
    # Irreversible: backfilled rows are indistinguishable from rows created when agents open
    # conversations, so we can't safely delete only the seeded ones. The table itself is dropped
    # by CreateConversationReadStates on rollback.
  end
end
