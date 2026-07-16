import { describe, it, expect, vi } from 'vitest';
import types from '../../../mutation-types';

vi.mock('shared/helpers/mitt', () => ({
  emitter: {
    emit: vi.fn(),
    on: vi.fn(),
    off: vi.fn(),
  },
}));

// eslint-disable-next-line import/first
import { mutations } from '../../conversations';

describe('per-agent unread mutations', () => {
  describe('#ADD_MESSAGE', () => {
    it('marks unread_for_agent when an incoming message arrives for a conversation not being viewed', () => {
      const state = { allConversations: [{ id: 1, messages: [] }], selectedChatId: 2 };
      mutations[types.ADD_MESSAGE](state, {
        conversation_id: 1,
        message_type: 0,
        created_at: 123,
        conversation: { unread_count: 1 },
      });
      expect(state.allConversations[0].unread_for_agent).toBe(true);
    });

    it('does not mark unread_for_agent for an outgoing message', () => {
      const state = { allConversations: [{ id: 1, messages: [] }], selectedChatId: 2 };
      mutations[types.ADD_MESSAGE](state, {
        conversation_id: 1,
        message_type: 1,
        created_at: 123,
        conversation: { unread_count: 0 },
      });
      expect(state.allConversations[0].unread_for_agent).toBeUndefined();
    });

    it('does not mark unread_for_agent while the agent is viewing the conversation', () => {
      const state = { allConversations: [{ id: 1, messages: [] }], selectedChatId: 1 };
      mutations[types.ADD_MESSAGE](state, {
        conversation_id: 1,
        message_type: 0,
        created_at: 123,
        conversation: { unread_count: 1 },
      });
      expect(state.allConversations[0].unread_for_agent).toBeUndefined();
    });
  });

  describe('#UPDATE_MESSAGE_UNREAD_COUNT', () => {
    it('clears unread_for_agent on mark-read (unreadCount defaults to 0)', () => {
      const state = { allConversations: [{ id: 1 }] };
      mutations[types.UPDATE_MESSAGE_UNREAD_COUNT](state, { id: 1, lastSeen: 100 });
      expect(state.allConversations[0].unread_for_agent).toBe(false);
    });

    it('sets unread_for_agent on mark-unread (unreadCount > 0)', () => {
      const state = { allConversations: [{ id: 1 }] };
      mutations[types.UPDATE_MESSAGE_UNREAD_COUNT](state, {
        id: 1,
        lastSeen: 100,
        unreadCount: 3,
      });
      expect(state.allConversations[0].unread_for_agent).toBe(true);
    });
  });

  describe('#ADD_CONVERSATION', () => {
    it('derives unread_for_agent from unread_count for a brand-new conversation', () => {
      const state = { allConversations: [] };
      mutations[types.ADD_CONVERSATION](state, { id: 9, messages: [], unread_count: 2 });
      expect(state.allConversations[0].unread_for_agent).toBe(true);
    });

    it('marks a new conversation with no unread incoming as read', () => {
      const state = { allConversations: [] };
      mutations[types.ADD_CONVERSATION](state, { id: 10, messages: [], unread_count: 0 });
      expect(state.allConversations[0].unread_for_agent).toBe(false);
    });

    it('does not override a server-provided unread_for_agent', () => {
      const state = { allConversations: [] };
      mutations[types.ADD_CONVERSATION](state, {
        id: 11,
        messages: [],
        unread_count: 0,
        unread_for_agent: true,
      });
      expect(state.allConversations[0].unread_for_agent).toBe(true);
    });
  });
});
