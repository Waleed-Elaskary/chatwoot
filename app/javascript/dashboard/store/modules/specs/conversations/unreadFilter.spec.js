import { describe, it, expect } from 'vitest';
import {
  applyPageFilters,
  filterByUnread,
} from '../../conversations/helpers';

describe('#filterByUnread', () => {
  it('passes the chain result through untouched when unreadOnly is not set', () => {
    expect(filterByUnread(true, undefined, false)).toBe(true);
    expect(filterByUnread(false, undefined, true)).toBe(false);
  });

  it('keeps only conversations that are unread for the agent when unreadOnly is set', () => {
    expect(filterByUnread(true, true, true)).toBe(true);
    expect(filterByUnread(true, true, false)).toBe(false);
  });

  it('respects an earlier false result in the filter chain', () => {
    expect(filterByUnread(false, true, true)).toBe(false);
  });
});

describe('#applyPageFilters with unreadOnly', () => {
  const base = { inbox_id: 2, status: 'open', meta: {}, labels: [] };

  it('includes a conversation that is unread for the current agent', () => {
    const conversation = { ...base, unread_for_agent: true };
    expect(
      applyPageFilters(conversation, { status: 'open', unreadOnly: true })
    ).toBe(true);
  });

  it('excludes a conversation that is read for the current agent', () => {
    const conversation = { ...base, unread_for_agent: false };
    expect(
      applyPageFilters(conversation, { status: 'open', unreadOnly: true })
    ).toBe(false);
  });

  it('excludes a conversation that has no per-agent flag yet', () => {
    const conversation = { ...base };
    expect(
      applyPageFilters(conversation, { status: 'open', unreadOnly: true })
    ).toBe(false);
  });

  it('does not affect results when unreadOnly is off', () => {
    const conversation = { ...base, unread_for_agent: false };
    expect(applyPageFilters(conversation, { status: 'open' })).toBe(true);
  });
});
