import React from "react";
import Table from "./table/table";
import {createColumnHelper, filterFns} from "@tanstack/react-table";

export class CourseSummaryTable extends React.Component {
  columnHelper = createColumnHelper();

  constructor(props) {
    super(props);
    this.state = {
      showHidden: false,
      columnFilters: [{id: "inactive", value: false}],
      columns: this.getColumns(props.student, props.assessments, props.marking_schemes),
    };
  }

  componentDidUpdate(prevProps) {
    if (
      prevProps.student !== this.props.student ||
      prevProps.assessments !== this.props.assessments ||
      prevProps.marking_schemes !== this.props.marking_schemes
    ) {
      this.setState({
        columns: this.getColumns(
          this.props.student,
          this.props.assessments,
          this.props.marking_schemes
        ),
      });
    }
  }

  static defaultProps = {
    assessments: [],
    marking_schemes: [],
    data: [],
  };

  getColumns = (student, assessments, marking_schemes) => {
    if (student) {
      return this.dataColumns(assessments, marking_schemes);
    } else {
      return [...this.nameColumns(), ...this.dataColumns(assessments, marking_schemes)];
    }
  };

  nameColumns = () => {
    const columnHelper = this.columnHelper;
    return [
      columnHelper.accessor("hidden", {
        id: "inactive",
        filterFn: (row, _columnId, filterValue) => {
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
      if (this.state.columnFilters[i].id !== "inactive") {
        columnFilters.push(this.state.columnFilters[i]);
      }
    }

    if (!showHidden) {
      columnFilters.push({id: "inactive", value: false});
    }
    this.setState({columnFilters, showHidden});
  };

  dataColumns = (assessments, marking_schemes) => {
    const columnHelper = this.columnHelper;
    const columns = [];

    assessments.forEach(data => {
      columns.push(
        columnHelper.accessor(`assessment_marks.${data.id}.mark`, {
          filterFn: filterFns.equalsString,
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
    marking_schemes.forEach(data => {
      columns.push(
        columnHelper.accessor(`weighted_marks.${data.id}.mark`, {
          filterFn: filterFns.equalsString,
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
          columns={this.state.columns}
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
