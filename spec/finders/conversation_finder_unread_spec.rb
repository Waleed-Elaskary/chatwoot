require 'rails_helper'

describe ConversationFinder, 'per-agent unread filter' do
  let!(:account) { create(:account) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let!(:unread_conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }
  let!(:read_conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }

  before do
    create(:inbox_member, user: agent, inbox: inbox)
    account.enable_features!(:filter_conversations_by_unread)

    create(:message, account: account, inbox: inbox, conversation: unread_conversation, message_type: :incoming, created_at: 1.hour.ago)
    create(:message, account: account, inbox: inbox, conversation: read_conversation, message_type: :incoming, created_at: 2.hours.ago)
    create(:conversation_read_state, account: account, conversation: read_conversation, user: agent, last_seen_at: 1.hour.ago)

    Current.account = account
  end

  after { Current.account = nil }

  def unread_ids
    described_class.new(agent, { status: 'all', unread: 'true' }).perform[:conversations].map(&:id)
  end

  it 'returns only conversations unread for the current agent' do
    expect(unread_ids).to include(unread_conversation.id)
    expect(unread_ids).not_to include(read_conversation.id)
  end

  it 'annotates unread_for_agent on the returned conversations' do
    conversations = described_class.new(agent, { status: 'all', unread: 'true' }).perform[:conversations]
    unread = conversations.find { |c| c.id == unread_conversation.id }

    expect(ActiveModel::Type::Boolean.new.cast(unread.unread_for_agent)).to be true
  end

  it 'ignores the filter when the feature is disabled' do
    account.disable_features!(:filter_conversations_by_unread)

    expect(unread_ids).to include(unread_conversation.id, read_conversation.id)
  end

  it 'includes an unassigned conversation the agent has never opened' do
    unassigned = create(:conversation, account: account, inbox: inbox, assignee: nil)
    create(:message, account: account, inbox: inbox, conversation: unassigned, message_type: :incoming, created_at: 1.hour.ago)

    expect(unread_ids).to include(unassigned.id)
  end

  it 'keeps a reassigned conversation unread for the new assignee even if a teammate read it' do
    teammate = create(:user, account: account, role: :agent)
    create(:inbox_member, user: teammate, inbox: inbox)
    convo = create(:conversation, account: account, inbox: inbox, assignee: teammate)
    create(:message, account: account, inbox: inbox, conversation: convo, message_type: :incoming, created_at: 1.hour.ago)
    create(:conversation_read_state, account: account, conversation: convo, user: teammate, last_seen_at: Time.current)

    convo.update!(assignee: agent)

    expect(unread_ids).to include(convo.id)
  end
end
