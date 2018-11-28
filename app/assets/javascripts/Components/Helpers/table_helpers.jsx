/**
 * @file
 * Provides generic helper functions for react tables
*/


export function stringFilter(filter, row) {
  /** Case insensitive, locale aware, string filter function */
  return String(row[filter.id]).toLocaleLowerCase().includes(filter.value.toLocaleLowerCase())
}

export function dateSort(a, b) {
  /** Sort values as dates */
  if (typeof a === 'string' && typeof b === 'string') {
    let a_date = Date.parse(a);
    let b_date = Date.parse(b);
    return a_date > b_date ? 1 : -1;
  } else {
    return a > b ? 1 : -1;
  }
}

