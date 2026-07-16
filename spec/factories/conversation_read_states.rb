# frozen_string_literal: true

FactoryBot.define do
  factory :conversation_read_state do
    conversation
    last_seen_at { Time.current }

    after(:build) do |read_state|
      read_state.account ||= read_state.conversation&.account
      read_state.user ||= create(:user, account: read_state.account)
    end
  end
end
