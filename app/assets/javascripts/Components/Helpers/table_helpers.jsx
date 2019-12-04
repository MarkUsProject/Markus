import React from "react";

/**
 * @file
 * Provides generic helper functions for react tables
*/


export function stringFilter(filter, row) {
  /** Case insensitive, locale aware, string filter function */
  return String(row[filter.id]).toLocaleLowerCase().includes(filter.value.toLocaleLowerCase());
};

export function dateSort(a, b) {
  /** Sort values as dates */
  return (Date.parse(a) || 0) > (Date.parse(b) || 0);
};

export function markingStateColumn(...override_keys) {
  return ({
    Header: I18n.t('activerecord.attributes.result.marking_state'),
    accessor: 'marking_state',
    Cell: row => {
      let marking_state = '';
      switch (row.original.marking_state) {
        case 'not_collected':
          marking_state = I18n.t('results.state.not_collected');
          break;
        case 'incomplete':
          marking_state = I18n.t('results.state.in_progress');
          break;
        case 'complete':
          marking_state = I18n.t('results.state.complete');
          break;
        case 'released':
          marking_state = I18n.t('results.state.released');
          break;
        case 'remark':
          marking_state = I18n.t('results.state.remark_requested');
          break;
        case 'before_due_date':
          marking_state = I18n.t('results.state.before_due_date');
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
        <option value='before_due_date'>{I18n.t('results.state.before_due_date')}</option>
        <option value='not_collected'>{I18n.t('results.state.not_collected')}</option>
        <option value='incomplete'>{I18n.t('results.state.in_progress')}</option>
        <option value='complete'>{I18n.t('results.state.complete')}</option>
        <option value='released'>{I18n.t('results.state.released')}</option>
        <option value='remark'>{I18n.t('results.state.remark_requested')}</option>
      </select>,
  ...override_keys})
};
