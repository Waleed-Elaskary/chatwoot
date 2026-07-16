require 'rails_helper'

RSpec.describe ConversationReadState do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it 'is invalid with a duplicate user for the same conversation' do
      existing = create(:conversation_read_state)
      duplicate = build(:conversation_read_state, conversation: existing.conversation, user: existing.user)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it 'allows the same user across different conversations' do
      first = create(:conversation_read_state)
      second = build(:conversation_read_state, user: first.user)

      expect(second).to be_valid
    end

    it 'defaults account_id from the conversation' do
      conversation = create(:conversation)
      read_state = build(:conversation_read_state, conversation: conversation, account: nil,
                                                   user: create(:user, account: conversation.account))
      read_state.valid?

      expect(read_state.account_id).to eq(conversation.account_id)
    end
  end
end
