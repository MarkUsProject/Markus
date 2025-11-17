import React from "react";
import Table from "./table/table";
import {createColumnHelper} from "@tanstack/react-table";

export class CourseSummaryTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showHidden: false,
      filtered: [{id: "hidden", value: false}],
    };
  }

  static defaultProps = {
    assessments: [],
    marking_schemes: [],
    data: [],
  };
  nameColumns() {
    const columnHelper = createColumnHelper();
    return [
      columnHelper.accessor("hidden", {
        id: "hidden",
        enableSorting: false,
        enableHiding: false,
        enableColumnFilter: true,
        cell: () => null,
        header: () => null,
        size: 0,
      }),
      columnHelper.accessor("user_name", {
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
  }

  // nameColumns = [
  //   {
  //     id: "hidden",
  //     accessor: "hidden",
  //     filterMethod: (filter, row) => {
  //       return filter.value || !row.hidden;
  //     },
  //     className: "rt-hidden",
  //     headerClassName: "rt-hidden",
  //     resizable: false,
  //     width: 0,
  //   },
  //   {
  //     Header: I18n.t("activerecord.attributes.user.user_name"),
  //     accessor: "user_name",
  //     filterable: true,
  //   },
  //   {
  //     Header: I18n.t("activerecord.attributes.user.first_name"),
  //     accessor: "first_name",
  //     filterable: true,
  //   },
  //   {
  //     Header: I18n.t("activerecord.attributes.user.last_name"),
  //     accessor: "last_name",
  //     filterable: true,
  //   },
  // ];

  updateShowHidden = event => {
    let showHidden = event.target.checked;
    let filtered = [];
    // for (let i = 0; i < this.state.filtered.length; i++) {
    //   if (this.state.filtered[i].id !== "hidden") {
    //     filtered.push(this.state.filtered[i]);
    //   }
    // }
    let columnFilters = this.state.columnFilters.filter(f => f.id !== "hidden");

    if (!showHidden) {
      columnFilters.push({id: "hidden", value: false});
    }
    this.setState({showHidden, columnFilters});
  };

  dataColumns = () => {
    const columnHelper = createColumnHelper();

    const columns = [];
    this.props.assessments.forEach(data => {
      columns.push(
        columnHelper.accessor(`assessment_marks.${data.id}.mark`, {
          header: () => data.name,
          cell: info => info.getValue(),
        })
      );
    });
    this.props.marking_schemes.forEach(data => {
      columns.push(
        columnHelper.accessor(`weighted_marks.${data.id}.mark`, {
          header: () => data.name,
          cell: info => info.getValue(),
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
          initialState={{sorting: [{id: "user_name", desc: false}]}}
          loading={this.props.loading}
          filtered={this.state.filtered}
          onFilteredChange={columnFilters => this.setState({columnFilters})}
          className={"auto-overflow"}
          getNoDataProps={() => ({
            loading: this.props.loading,
          })}
        />
        ,
      </>
    );
  }
}
