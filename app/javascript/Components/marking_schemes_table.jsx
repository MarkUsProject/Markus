import React from "react";
import {createRoot} from "react-dom/client";

import ReactTable from "react-table";
import {faPencil, faTrashCan} from "@fortawesome/free-solid-svg-icons";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

class MarkingSchemeTable extends React.Component {
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
          columns: res.columns,
          loading: false,
        });
      });
  }

  nameColumns = [
    {
      Header: I18n.t("activerecord.attributes.marking_schemes.name"),
      accessor: "name",
      filterable: true,
    },
  ];

  modifyColumn = [
    {
      Header: I18n.t("actions"),
      Cell: ({original}) => (
        <span>
          <a
            href={original.edit_link}
            data-remote="true"
            aria-label={I18n.t("edit")}
            title={I18n.t("edit")}
          >
            <FontAwesomeIcon icon={faPencil} />
          </a>
          &nbsp;|&nbsp;
          <a
            href={original.delete_link}
            data-method="delete"
            aria-label={I18n.t("delete")}
            title={I18n.t("delete")}
          >
            <FontAwesomeIcon icon={faTrashCan} />
          </a>
        </span>
      ),
      sortable: false,
    },
  ];

  render() {
    return (
      <ReactTable
        data={this.state.data}
        columns={this.nameColumns.concat(this.state.columns).concat(this.modifyColumn)}
        defaultSorted={[
          {
            id: "name",
          },
        ]}
        loading={this.state.loading}
      />
    );
  }
}

export function makeMarkingSchemeTable(elem, props) {
  const root = createRoot(elem);
  root.render(<MarkingSchemeTable {...props} />);
}
