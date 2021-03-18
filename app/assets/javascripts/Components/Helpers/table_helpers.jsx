import React from "react";

/**
 * @file
 * Provides generic helper functions for react tables
*/

export function defaultSort(a, b) {
  // Sort values, putting undefined/nulls below all other values.
  // Based on react-table v6 defaultSortMethod (https://github.com/tannerlinsley/react-table/tree/v6/),
  // but not string-based.
  if ((a === undefined || a === null) && (b === undefined || b === null)) {
    return 0;
  } else if (a === undefined || a === null) {
    return -1;
  } else if (b === undefined || b === null) {
    return 1;
  } else {
    // force any string values to lowercase
    a = typeof a === 'string' ? a.toLowerCase() : a
    b = typeof b === 'string' ? b.toLowerCase() : b
    // Return either 1 or -1 to indicate a sort priority
    if (a > b) {
      return 1;
    }
    if (a < b) {
      return -1;
    }
    // returning 0, undefined or any falsey value will use subsequent sorts or
    // the index as a tiebreaker
    return 0;
  }
}

export function stringFilter(filter, row) {
  /** Case insensitive, locale aware, string filter function */
  return String(row[filter.id]).toLocaleLowerCase().includes(filter.value.toLocaleLowerCase());
};

export function dateSort(a, b) {
  /** Sort values as dates */
  if (!a && !b) {
    return 0;
  } else if (!a) {
    return -1;
  } else if (!b) {
    return 1;
  } else {
    let a_date = new Date(a);
    let b_date = new Date(b);
    return (a_date || 0) > (b_date || 0);
  }
};

export function durationSort(a, b) {
  /** Sort values as a duration in weeks, days, hours, etc. */
  a = [a.weeks || -1, a.days || -1, a.hours || -1, a.minutes || -1, a.seconds || -1];
  b = [b.weeks || -1, b.days || -1, b.hours || -1, b.minutes || -1, b.seconds || -1];
  if (a < b) {
    return 1;
  } else if (b < a) {
    return -1;
  } else {
    return 0;
  }
};

export function markingStateColumn(...override_keys) {
  return ({
    Header: I18n.t('activerecord.attributes.result.marking_state'),
    accessor: 'marking_state',
    Cell: row => {
      let marking_state = '';
      switch (row.original.marking_state) {
        case 'not_collected':
          marking_state = I18n.t('submissions.state.not_collected');
          break;
        case 'incomplete':
          marking_state = I18n.t('submissions.state.in_progress');
          break;
        case 'complete':
          marking_state = I18n.t('submissions.state.complete');
          break;
        case 'released':
          marking_state = I18n.t('submissions.state.released');
          break;
        case 'remark':
          marking_state = I18n.t('submissions.state.remark_requested');
          break;
        case 'before_due_date':
          marking_state = I18n.t('submissions.state.before_due_date');
          break;
        default:
          // should not get here
          marking_state = row.original.marking_state
      }
      return ( marking_state );
    },
    filterMethod: (filter, row) => {
      if (filter.value === 'all') {
        return true;
      } else {
        return filter.value === row[filter.id];
      }
    },
    Filter: ({ filter, onChange }) =>
      <select
        onChange={event => onChange(event.target.value)}
        style={{ width: '100%' }}
        value={filter ? filter.value : 'all'}
      >
        <option value='all'>{I18n.t('all')}</option>
        <option value='before_due_date'>{I18n.t('submissions.state.before_due_date')}</option>
        <option value='not_collected'>{I18n.t('submissions.state.not_collected')}</option>
        <option value='incomplete'>{I18n.t('submissions.state.in_progress')}</option>
        <option value='complete'>{I18n.t('submissions.state.complete')}</option>
        <option value='released'>{I18n.t('submissions.state.released')}</option>
        <option value='remark'>{I18n.t('submissions.state.remark_requested')}</option>
      </select>,
  ...override_keys})
};
