import React from "react";
import * as I18n from "i18n-js";
import "translations";

/**
 * @file
 * Provides generic helper functions and components for react-table tables.
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
    a = typeof a === "string" ? a.toLowerCase() : a;
    b = typeof b === "string" ? b.toLowerCase() : b;
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

/**
 * Case insensitive, locale aware, string filter function
 */
export function stringFilterMethod(filter, row) {
  return String(row[filter.id])
    .toLocaleLowerCase()
    .includes(String(filter.value).toLocaleLowerCase());
}

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
}

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
}

/**
 * Text-based search filter. Based on react-table's default search filter,
 * with an additional aria-label attribute.
 */
export function textFilter({filter, onChange, column}) {
  return (
    <input
      type="text"
      style={{
        width: "100%",
      }}
      placeholder={column.Placeholder}
      value={filter ? filter.value : ""}
      aria-label={`${I18n.t("search")} ${column.Header || ""}`}
      onChange={event => onChange(event.target.value)}
    />
  );
}

/**
 * Select-based search filter. Options are generated from the custom column attribute
 * filterOptions, which is a list of objects with keys "value" and "text".
 * A default "all" option is prepended to the list of options; the text can be
 * customized by setting the filterAllOptionText column attribute.
 */
export function selectFilter({filter, onChange, column}) {
  let options = (column.filterOptions || []).map(({value, text}) => (
    <option value={value} key={value}>
      {text}
    </option>
  ));
  let allOptionText = column.filterAllOptionText || I18n.t("all");
  options.unshift(
    <option value="all" key="all">
      {allOptionText}
    </option>
  );

  return (
    <select
      onChange={event => onChange(event.target.value)}
      style={{width: "100%"}}
      value={filter ? filter.value : "all"}
      aria-label={I18n.t("filter_by", {name: column.Header})}
    >
      {options}
    </select>
  );
}

export function markingStateColumn(...override_keys) {
  return {
    Header: I18n.t("activerecord.attributes.result.marking_state"),
    accessor: "marking_state",
    Cell: row => {
      let marking_state = "";
      switch (row.original.marking_state) {
        case "not_collected":
          marking_state = I18n.t("submissions.state.not_collected");
          break;
        case "incomplete":
          marking_state = I18n.t("submissions.state.in_progress");
          break;
        case "complete":
          marking_state = I18n.t("submissions.state.complete");
          break;
        case "released":
          marking_state = I18n.t("submissions.state.released");
          break;
        case "remark":
          marking_state = I18n.t("submissions.state.remark_requested");
          break;
        case "before_due_date":
          marking_state = I18n.t("submissions.state.before_due_date");
          break;
        default:
          // should not get here
          marking_state = row.original.marking_state;
      }
      return marking_state;
    },
    filterMethod: (filter, row) => {
      if (filter.value === "all") {
        return true;
      } else {
        return filter.value === row[filter.id];
      }
    },
    filterOptions: [
      {
        value: "before_due_date",
        text: I18n.t("submissions.state.before_due_date"),
      },
      {
        value: "not_collected",
        text: I18n.t("submissions.state.not_collected"),
      },
      {value: "incomplete", text: I18n.t("submissions.state.in_progress")},
      {value: "complete", text: I18n.t("submissions.state.complete")},
      {value: "released", text: I18n.t("submissions.state.released")},
      {value: "remark", text: I18n.t("submissions.state.remark_requested")},
    ],
    Filter: selectFilter,
    ...override_keys,
  };
}
