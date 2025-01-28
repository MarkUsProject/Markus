import React from "react";
import ReactTable from "react-table";
import {createRoot} from "react-dom/client";
import ReactDOM from "react-dom";

class AnnotationUsagePanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      applications: null,
      details: false,
    };
  }

  toggle = () => {
    if (this.state.applications === null) {
      this.fetchData();
    } else {
      this.setState({details: !this.state.details});
    }
  };

  columns = [
    {
      Header: I18n.t("annotations.used_by"),
      accessor: row => "(" + row["user_name"] + ") " + row["first_name"] + " " + row["last_name"],
      id: "user",
      minWidth: 200,
      PivotValue: ({value}) => value,
    },
    {
      Header: I18n.t("activerecord.models.submission.one"),
      accessor: "group_name",
      aggregate: (vals, pivots) => {
        let usageCount = pivots.reduce((accumulator, p) => accumulator + p._original["count"], 0);
        return I18n.t("annotations.used_times", {count: usageCount});
      },
      sortable: false,
      Aggregated: row => "(" + row.value + ")",
      filterMethod: (filter, row) => {
        if (row._subRows === undefined) {
          return row[filter.id].toLowerCase().includes(filter.value.toLowerCase());
        } else {
          return row._subRows.some(sr =>
            sr["group_name"].toLowerCase().includes(filter.value.toLowerCase())
          );
        }
      },
      Cell: row => {
        return (
          <a href={Routes.edit_course_result_path(this.props.course_id, row.original["result_id"])}>
            {row.original["group_name"] +
              (row.original["count"] > 1 ? " (" + row.original["count"] + ")" : "")}
          </a>
        );
      },
    },
  ];

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
          columns={this.columns}
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
