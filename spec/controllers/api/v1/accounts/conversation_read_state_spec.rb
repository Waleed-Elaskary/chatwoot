require 'rails_helper'

# Per-agent read-state write hooks on update_last_seen / unread. The team-wide agent_last_seen_at
# behavior is covered by conversations_controller_spec.rb; this focuses on conversation_read_states.
RSpec.describe 'Conversation per-agent read state', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:teammate) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before do
    create(:inbox_member, user: agent, inbox: inbox)
    create(:inbox_member, user: teammate, inbox: inbox)
    account.enable_features!(:filter_conversations_by_unread)
  end

  describe 'POST /update_last_seen' do
    it "records the current agent's read state without touching a teammate's" do
      create(:conversation_read_state, account: account, conversation: conversation, user: teammate, last_seen_at: 1.day.ago)

      post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)

      agent_state = ConversationReadState.find_by(conversation: conversation, user: agent)
      expect(agent_state).to be_present
      expect(agent_state.last_seen_at).to be_within(2.seconds).of(Time.current)

      teammate_state = ConversationReadState.find_by(conversation: conversation, user: teammate)
      expect(teammate_state.last_seen_at).to be_within(1.second).of(1.day.ago)
    end

    it 'does not write a read state when the feature is disabled' do
      account.disable_features!(:filter_conversations_by_unread)

      post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
           headers: agent.create_new_auth_token,
           as: :json

      expect(ConversationReadState.where(conversation: conversation, user: agent)).to be_empty
    end
  end

  describe 'POST /unread' do
    it "backdates the current agent's read state so the conversation is unread for them again" do
      create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming)
      create(:conversation_read_state, account: account, conversation: conversation, user: agent, last_seen_at: Time.current)

      post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/unread",
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(account.conversations.unread_for(agent)).to include(conversation)
    end
  end
end
