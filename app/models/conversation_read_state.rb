# == Schema Information
#
# Table name: conversation_read_states
#
#  id              :bigint           not null, primary key
#  last_seen_at    :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_conversation_read_states_on_account_id                (account_id)
#  index_conversation_read_states_on_conversation_id           (conversation_id)
#  index_conversation_read_states_on_user_and_conversation     (user_id,conversation_id) UNIQUE
#

# Tracks, per agent, the last time that agent saw a given conversation. This is the
# per-user counterpart to Conversation#agent_last_seen_at (which is team-wide) and powers
# the per-agent "unread" conversation filter. See Conversation.unread_for.
class ConversationReadState < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :user

  validates :user_id, uniqueness: { scope: :conversation_id }

  before_validation :ensure_account_id

  private

  def ensure_account_id
    self.account_id ||= conversation&.account_id
  end
end
