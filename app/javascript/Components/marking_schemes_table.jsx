import React from "react";
import {createRoot} from "react-dom/client";

import {faPencil, faTrashCan} from "@fortawesome/free-solid-svg-icons";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import {createColumnHelper} from "@tanstack/react-table";
import Table from "./table/table";

export class MarkingSchemeTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      columns: [],
      loading: true,
    };
    this.fetchData = this.fetchData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    fetch(Routes.populate_course_marking_schemes_path(this.props.course_id), {
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
        this.setState({
          data: res.data,
          columns: this.getColumns(res.columns),
          loading: false,
        });
      });
  }

  getColumns = columns => {
    const columnHelper = createColumnHelper();

    const nameColumn = columnHelper.accessor("name", {
      header: I18n.t("activerecord.attributes.marking_schemes.name"),
      enableColumnFilter: true,
    });

    const assessmentWeightColumnDefs = columns.map(col =>
      columnHelper.accessor(col.accessor, {
        header: col.Header,
        minSize: col.minWidth,
        enableColumnFilter: false,
        meta: {
          className: col.className,
        },
      })
    );

    const modifyColumn = columnHelper.display({
      header: I18n.t("actions"),
      cell: props => (
        <span>
          <a
            href={props.row.original.edit_link}
            data-remote="true"
            aria-label={I18n.t("edit")}
            title={I18n.t("edit")}
          >
            <FontAwesomeIcon icon={faPencil} />
          </a>
          &nbsp;|&nbsp;
          <a
            href={props.row.original.delete_link}
            data-method="delete"
            aria-label={I18n.t("delete")}
            title={I18n.t("delete")}
          >
            <FontAwesomeIcon icon={faTrashCan} />
          </a>
        </span>
      ),
      enableSorting: false,
    });

    return [nameColumn, ...assessmentWeightColumnDefs, modifyColumn];
  };
  render() {
    return (
      <Table
        data={this.state.data}
        columns={this.state.columns}
        initialState={{
          sorting: [{id: "name"}],
        }}
        loading={this.state.loading}
      />
    );
  }
}

export function makeMarkingSchemeTable(elem, props) {
  const root = createRoot(elem);
  root.render(<MarkingSchemeTable {...props} />);
}
