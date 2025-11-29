import React from "react";
import Table from "./table/table";
import {createColumnHelper} from "@tanstack/react-table";

export class CourseSummaryTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showHidden: false,
      columnFilters: [{id: "hidden", value: false}],
    };

    this.columnHelper = createColumnHelper();
  }

  static defaultProps = {
    assessments: [],
    marking_schemes: [],
    data: [],
  };
  nameColumns = () => {
    const columnHelper = this.columnHelper;
    return [
      columnHelper.accessor("hidden", {
        id: "hidden",
        filterFn: (row, columnId, filterValue) => {
          // Show all rows if filter true, else only show non-hidden rows
          return filterValue || !row.original.hidden;
        },
        enableColumnFilter: true,
        enableHiding: false,
        meta: {
          className: "rt-hidden",
          headerClassName: "rt-hidden",
        },
        cell: () => null,
        header: () => null,
        size: 0,
      }),
      columnHelper.accessor("user_name", {
        id: "user_name",
        header: () => I18n.t("activerecord.attributes.user.user_name"),
        enableColumnFilter: true,
      }),
      columnHelper.accessor("first_name", {
        header: () => I18n.t("activerecord.attributes.user.first_name"),
        enableColumnFilter: true,
      }),
      columnHelper.accessor("last_name", {
        header: () => I18n.t("activerecord.attributes.user.last_name"),
        enableColumnFilter: true,
      }),
    ];
  };

  updateShowHidden = event => {
    let showHidden = event.target.checked;
    let columnFilters = [];

    for (let i = 0; i < this.state.columnFilters.length; i++) {
      if (this.state.columnFilters[i].id !== "hidden") {
        columnFilters.push(this.state.columnFilters[i]);
      }
    }

    if (!showHidden) {
      columnFilters.push({id: "hidden", value: false});
    }
    this.setState({columnFilters, showHidden});
  };

  dataColumns = () => {
    const columnHelper = this.columnHelper;
    const columns = [];

    this.props.assessments.forEach(data => {
      columns.push(
        columnHelper.accessor(`assessment_marks.${data.id}.mark`, {
          // Custom filter function for numeric columns
          filterFn: (row, columnId, filterValue) => {
            const cellValue = row.getValue(columnId);
            if (cellValue == null) return false;
            return cellValue.toString().includes(filterValue);
          },
          enableColumnFilter: true,
          header: () => data.name,
          cell: info => info.getValue(),
          meta: {
            className: "number",
            headerStyle: {textAlign: "right"},
          },
        })
      );
    });
    this.props.marking_schemes.forEach(data => {
      columns.push(
        columnHelper.accessor(`weighted_marks.${data.id}.mark`, {
          // Custom filter function for numeric columns
          filterFn: (row, columnId, filterValue) => {
            const cellValue = row.getValue(columnId);
            if (cellValue == null) return false;
            return cellValue.toString().includes(filterValue);
          },
          enableColumnFilter: true,
          header: () => data.name,
          cell: info => info.getValue(),
          meta: {
            className: "number",
            headerStyle: {textAlign: "right"},
          },
        })
      );
    });
    return columns;
  };

  render() {
    const columns = this.props.student
      ? this.dataColumns()
      : [...this.nameColumns(), ...this.dataColumns()];

    return (
      <>
        {!this.props.student && (
          <div key="show-hidden" style={{height: "2em"}}>
            <input
              id="show_hidden"
              name="show_hidden"
              type="checkbox"
              checked={this.state.showHidden}
              onChange={this.updateShowHidden}
              style={{marginLeft: "5px", marginRight: "5px"}}
            />
            <label htmlFor="show_hidden">{I18n.t("students.display_inactive")}</label>
          </div>
        )}
        <Table
          data={this.props.data}
          columns={columns}
          columnFilters={this.state.columnFilters}
          onColumnFiltersChange={updaterOrValue => {
            this.setState(prevState => {
              const newFilters =
                typeof updaterOrValue === "function"
                  ? updaterOrValue(prevState.columnFilters)
                  : updaterOrValue;
              return {columnFilters: newFilters};
            });
          }}
          initialState={{sorting: [{id: "user_name", desc: false}]}}
          loading={this.props.loading}
          className={"auto-overflow"}
          getNoDataProps={() => ({
            loading: this.props.loading,
          })}
        />
      </>
    );
  }
}
