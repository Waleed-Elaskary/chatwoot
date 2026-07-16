require 'rails_helper'

# Covers the per-agent unread predicate (Conversation.unread_for / #unread_for_agent?), the single
# source of truth shared by the quick toggle, the advanced filter, and the serializer flag.
RSpec.describe Conversation do
  describe '.unread_for and #unread_for_agent?' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:other_agent) { create(:user, account: account, role: :agent) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    def add_incoming(conv, at)
      create(:message, account: account, inbox: inbox, conversation: conv, message_type: :incoming, created_at: at)
    end

    def mark_seen(user, conv, at)
      create(:conversation_read_state, account: account, conversation: conv, user: user, last_seen_at: at)
    end

    context 'when the agent has never opened the conversation (no read-state row)' do
      it 'is unread when there is an incoming message' do
        add_incoming(conversation, 1.hour.ago)

        expect(account.conversations.unread_for(agent)).to include(conversation)
        expect(conversation.unread_for_agent?(agent)).to be true
      end

      it 'is not unread when the only messages are outgoing' do
        create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing, created_at: 1.hour.ago)

        expect(account.conversations.unread_for(agent)).not_to include(conversation)
        expect(conversation.unread_for_agent?(agent)).to be false
      end
    end

    context 'when the agent has already opened the conversation' do
      it 'is not unread when no incoming message is newer than their last_seen_at' do
        add_incoming(conversation, 2.hours.ago)
        mark_seen(agent, conversation, 1.hour.ago)

        expect(account.conversations.unread_for(agent)).not_to include(conversation)
      end

      it 'is unread when a new incoming message arrives after their last_seen_at' do
        mark_seen(agent, conversation, 2.hours.ago)
        add_incoming(conversation, 1.hour.ago)

        expect(account.conversations.unread_for(agent)).to include(conversation)
      end

      it 'ignores outgoing messages created after their last_seen_at' do
        mark_seen(agent, conversation, 2.hours.ago)
        create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing, created_at: 1.hour.ago)

        expect(account.conversations.unread_for(agent)).not_to include(conversation)
      end
    end

    context 'with two agents on the same conversation (per-agent divergence)' do
      it 'is unread only for the agent who has not seen the latest incoming message' do
        add_incoming(conversation, 1.hour.ago)
        mark_seen(agent, conversation, Time.current)
        # other_agent has no read-state row

        expect(account.conversations.unread_for(agent)).not_to include(conversation)
        expect(account.conversations.unread_for(other_agent)).to include(conversation)
      end
    end

    context 'with an unassigned conversation' do
      it 'is unread until the agent opens it, regardless of assignment' do
        unassigned = create(:conversation, account: account, inbox: inbox, assignee: nil)
        add_incoming(unassigned, 1.hour.ago)

        expect(account.conversations.unread_for(agent)).to include(unassigned)

        mark_seen(agent, unassigned, Time.current)

        expect(account.conversations.unread_for(agent)).not_to include(unassigned)
      end
    end

    context 'on reassignment' do
      it 'is unread for the new assignee even though the previous assignee already read it' do
        add_incoming(conversation, 1.hour.ago)

        # previous assignee reads it...
        conversation.update!(assignee: other_agent)
        mark_seen(other_agent, conversation, Time.current)

        # ...then it is handed off to an agent who has never opened it
        conversation.update!(assignee: agent)

        expect(account.conversations.unread_for(agent)).to include(conversation)
        expect(account.conversations.unread_for(other_agent)).not_to include(conversation)
      end
    end
  end
end
