require 'rails_helper'

describe Conversations::FilterService, 'unread attribute' do
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
  end

  def filter_ids(operator, value)
    payload = [
      { attribute_key: 'unread', filter_operator: operator, values: [value], query_operator: nil }.with_indifferent_access
    ]
    described_class.new({ payload: payload, page: 1 }, agent, account).perform[:conversations].map(&:id)
  end

  it 'returns unread conversations for equal_to true' do
    ids = filter_ids('equal_to', 'true')
    expect(ids).to include(unread_conversation.id)
    expect(ids).not_to include(read_conversation.id)
  end

  it 'returns read conversations for equal_to false' do
    ids = filter_ids('equal_to', 'false')
    expect(ids).to include(read_conversation.id)
    expect(ids).not_to include(unread_conversation.id)
  end

  it 'returns read conversations for not_equal_to true' do
    ids = filter_ids('not_equal_to', 'true')
    expect(ids).to include(read_conversation.id)
    expect(ids).not_to include(unread_conversation.id)
  end

  it 'returns unread conversations for not_equal_to false' do
    ids = filter_ids('not_equal_to', 'false')
    expect(ids).to include(unread_conversation.id)
    expect(ids).not_to include(read_conversation.id)
  end

  it 'raises an invalid-attribute error when the feature is disabled' do
    account.disable_features!(:filter_conversations_by_unread)

    expect { filter_ids('equal_to', 'true') }.to raise_error(CustomExceptions::CustomFilter::InvalidAttribute)
  end
end
