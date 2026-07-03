import React from "react";
import {createRoot} from "react-dom/client";
import {createColumnHelper} from "@tanstack/react-table";
import Table from "./table/table";

import {caseSensitiveIncludes} from "./Helpers/table_helpers";

const columnHelper = createColumnHelper();
class AnnotationUsagePanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      applications: null,
      columnFilters: [],
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
    columnHelper.accessor(
      row => "(" + row.user_name + ") " + row.first_name + " " + row.last_name,
      {
        header: I18n.t("annotations.used_by"),
        id: "user",
        minSize: 200,
        cell: ({getValue, row}) => {
          if (row.getIsGrouped()) {
            return getValue();
          }
          return null;
        },
      }
    ),
    columnHelper.accessor("group_name", {
      header: I18n.t("activerecord.models.submission.one"),
      enableSorting: false,
      aggregationFn: (columnId, leafRows, childRows) => {
        return leafRows.reduce((acc, row) => acc + row.original.count, 0);
      },
      cell: props => {
        if (props.row.getIsGrouped()) {
          return I18n.t("annotations.used_times", {
            count: props.row.getValue("group_name"),
          });
        }

        return (
          <a
            href={Routes.edit_course_result_path(
              this.props.course_id,
              props.row.original.result_id
            )}
          >
            {props.row.original.group_name +
              (props.row.original.count > 1 ? ` (${props.row.original.count})` : "")}
          </a>
        );
      },
      filterFn: (row, columnId, filterValue) => {
        const value = filterValue?.value;
        const caseSensitive = filterValue?.caseSensitive;

        if (!value) return true;

        return caseSensitiveIncludes(row.original[columnId], value, caseSensitive);
      },
      meta: {
        filterVariant: "case-sensitive-text",
      },
    }),
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
        <Table
          data={this.state.applications}
          columns={this.columns}
          initialState={{
            grouping: ["user"],
          }}
          columnFilters={this.state.columnFilters}
          onColumnFiltersChange={updaterOrValue => {
            this.setState(prevState => {
              let newFilters =
                typeof updaterOrValue === "function"
                  ? updaterOrValue(prevState.columnFilters)
                  : updaterOrValue;
              return {columnFilters: newFilters};
            });
          }}
          renderSubComponent={({row}) => (
            <div>
              {row.subRows.map(subRow => (
                <div key={subRow.id}>{subRow.original.group_name}</div>
              ))}
            </div>
          )}
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
