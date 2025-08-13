import React from "react";
import {Grid} from "react-loader-spinner";

/**
 * @file
 * Provides generic helper functions and components for react-table tables.
 */

export function customLoadingProp(props) {
  const {loading} = props;

  if (loading) {
    return (
      <div
        className="flex gap-4"
        style={{
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          height: "50px",
        }}
        data-testid="loading-spinner"
      >
        <Grid
          visible={true}
          height="25"
          width="25"
          color="#31649B"
          ariaLabel="grid-loading"
          radius="12.5"
          wrapperStyle={{}}
          wrapperClass="grid-wrapper"
        />
      </div>
    );
  }

  return null;
}

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
    return (a_date || 0) - (b_date || 0);
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

export function markingStateColumn(marking_states, markingStateFilter, ...override_keys) {
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
    filterAllOptionText:
      I18n.t("all") +
      (markingStateFilter === "all"
        ? ` (${Object.values(marking_states).reduce((a, b) => a + b)})`
        : ""),
    filterOptions: [
      {
        value: "before_due_date",
        text:
          I18n.t("submissions.state.before_due_date") +
          (["before_due_date", "all"].includes(markingStateFilter)
            ? ` (${marking_states["before_due_date"]})`
            : ""),
      },
      {
        value: "not_collected",
        text:
          I18n.t("submissions.state.not_collected") +
          (["not_collected", "all"].includes(markingStateFilter)
            ? ` (${marking_states["not_collected"]})`
            : ""),
      },
      {
        value: "incomplete",
        text:
          I18n.t("submissions.state.in_progress") +
          (["incomplete", "all"].includes(markingStateFilter)
            ? ` (${marking_states["incomplete"]})`
            : ""),
      },
      {
        value: "complete",
        text:
          I18n.t("submissions.state.complete") +
          (["complete", "all"].includes(markingStateFilter)
            ? ` (${marking_states["complete"]})`
            : ""),
      },
      {
        value: "released",
        text:
          I18n.t("submissions.state.released") +
          (["released", "all"].includes(markingStateFilter)
            ? ` (${marking_states["released"]})`
            : ""),
      },
      {
        value: "remark",
        text:
          I18n.t("submissions.state.remark_requested") +
          (["remark", "all"].includes(markingStateFilter) ? ` (${marking_states["remark"]})` : ""),
      },
    ],
    Filter: selectFilter,
    ...override_keys,
  };
}

export function getMarkingStates(data) {
  const markingStates = {
    not_collected: 0,
    incomplete: 0,
    complete: 0,
    released: 0,
    remark: 0,
    before_due_date: 0,
  };
  data.forEach(row => {
    markingStates[row["marking_state"]] += 1;
  });
  return markingStates;
}

export function customNoDataComponent({children, loading}) {
  if (loading) {
    return null;
  }
  return <p className="rt-no-data">{children}</p>;
}

export function customNoDataProps({state}) {
  return {loading: state.loading};
}

export function customNoDataText(props) {
  const {loading} = props;
  if (loading) {
    return "";
  }
  return I18n.t("students.empty_table");
}
