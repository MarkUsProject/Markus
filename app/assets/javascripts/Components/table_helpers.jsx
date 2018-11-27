
export function stringFilter(filter, row) {
  return String(row[filter.id]).toLocaleLowerCase().includes(filter.value.toLocaleLowerCase())
}

export function dateSort(a, b) {
  if (typeof a === 'string' && typeof b === 'string') {
    let a_date = Date.parse(a);
    let b_date = Date.parse(b);
    return a_date > b_date ? 1 : -1;
  } else {
    return a > b ? 1 : -1;
  }
}

