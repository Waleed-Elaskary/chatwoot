import { describe, it, expect } from 'vitest';
import { matchesFilters } from '../filterHelpers';

// The advanced-filter `unread` attribute is a per-agent boolean sent with string option ids
// ('true' / 'false') and evaluated client-side against conversation.unread_for_agent.
const unreadFilter = (operator, id) => [
  {
    attribute_key: 'unread',
    filter_operator: operator,
    values: [{ id, name: id }],
    query_operator: null,
  },
];

describe('filterHelpers – unread attribute', () => {
  it('matches an unread conversation with equal_to true', () => {
    expect(
      matchesFilters({ unread_for_agent: true }, unreadFilter('equal_to', 'true'))
    ).toBe(true);
  });

  it('does not match a read conversation with equal_to true', () => {
    expect(
      matchesFilters({ unread_for_agent: false }, unreadFilter('equal_to', 'true'))
    ).toBe(false);
  });

  it('matches a read conversation with equal_to false', () => {
    expect(
      matchesFilters({ unread_for_agent: false }, unreadFilter('equal_to', 'false'))
    ).toBe(true);
  });

  it('matches a read conversation with not_equal_to true', () => {
    expect(
      matchesFilters(
        { unread_for_agent: false },
        unreadFilter('not_equal_to', 'true')
      )
    ).toBe(true);
  });

  it('matches an unread conversation with not_equal_to false', () => {
    expect(
      matchesFilters(
        { unread_for_agent: true },
        unreadFilter('not_equal_to', 'false')
      )
    ).toBe(true);
  });

  it('does not match when the per-agent flag is absent', () => {
    expect(matchesFilters({}, unreadFilter('equal_to', 'true'))).toBe(false);
  });
});
