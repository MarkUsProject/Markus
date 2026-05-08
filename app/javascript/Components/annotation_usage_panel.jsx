import React from "react";
import ReactTable from "react-table";
import {createRoot} from "react-dom/client";
import ReactDOM from "react-dom";

import {caseSensitiveIncludes, caseSensitiveTextFilter} from "./Helpers/table_helpers";

class AnnotationUsagePanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      applications: null,
      details: false,
      caseSensitive: true,
      columns: this.getColumns(true),
    };
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevState.caseSensitive !== this.state.caseSensitive) {
      this.setState({columns: this.getColumns(this.state.caseSensitive)});
    }
  }

  toggle = () => {
    if (this.state.applications === null) {
      this.fetchData();
    } else {
      this.setState({details: !this.state.details});
    }
  };

  toggleCaseSensitive = () => {
    this.setState(state => ({caseSensitive: !state.caseSensitive}));
  };

  groupNameFilter = caseSensitiveTextFilter({
    getCaseSensitive: () => this.state.caseSensitive,
    onToggle: this.toggleCaseSensitive,
  });

  getColumns = caseSensitive => {
    return [
      {
        Header: I18n.t("annotations.used_by"),
        accessor: row => `(${row.user_name}) ${row.first_name} ${row.last_name}`,
        id: "user",
        minWidth: 200,
        PivotValue: ({value}) => value,
      },
      {
        Header: I18n.t("activerecord.models.submission.one"),
        accessor: "group_name",
        id: "group_name",
        aggregate: (vals, pivots) => {
          const usageCount = pivots.reduce((sum, p) => sum + p._original.count, 0);
          return I18n.t("annotations.used_times", {count: usageCount});
        },
        sortable: false,
        Aggregated: row => `(${row.value})`,
        Filter: this.groupNameFilter,
        filterMethod: (filter, row) => {
          if (row._subRows === undefined) {
            return caseSensitiveIncludes(row[filter.id], filter.value, caseSensitive);
          }
          return row._subRows.some(sr =>
            caseSensitiveIncludes(sr.group_name, filter.value, caseSensitive)
          );
        },
        Cell: row => {
          const {group_name, count, result_id} = row.original;
          const suffix = count > 1 ? ` (${count})` : "";
          return (
            <a href={Routes.edit_course_result_path(this.props.course_id, result_id)}>
              {`${group_name}${suffix}`}
            </a>
          );
        },
      },
    ];
  };

  fetchData = () => {
    const url = Routes.annotation_text_uses_course_assignment_annotation_categories_path(
      this.props.course_id,
      this.props.assignment_id,
      {
        annotation_text_id: this.props.annotation_id,
      }
    );
    fetch(url, {
      headers: {
        Accept: "application/json",
      },
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(res => {
        this.setState({applications: res, details: true});
      });
  };

  render() {
    let numUsed = <p>{I18n.t("annotations.count") + this.props.num_used}</p>;
    let displayToggle = (
      <p>
        <a onClick={this.toggle} className="button">
          {I18n.t("annotations.usage")}
        </a>
      </p>
    );
    if (this.state.details) {
      let annotation_table = (
        <ReactTable
          className="auto-overflow"
          data={this.state.applications}
          columns={this.state.columns}
          filterable
          pivotBy={["user"]}
        />
      );
      return (
        <fieldset>
          {numUsed}
          {displayToggle}
          {annotation_table}
        </fieldset>
      );
    } else {
      return (
        <fieldset>
          {numUsed}
          {displayToggle}
        </fieldset>
      );
    }
  }
}

export function makeAnnotationUsagePanel(elem, props) {
  const root = createRoot(elem);
  return root.render(<AnnotationUsagePanel {...props} />);
}

export {AnnotationUsagePanel};
