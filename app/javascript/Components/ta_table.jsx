import React from "react";
import {createRoot} from "react-dom/client";
import PropTypes from "prop-types";

import {faPencil, faTrashCan} from "@fortawesome/free-solid-svg-icons";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

import Table from "./table/table";
import {createColumnHelper} from "@tanstack/react-table";

class TATable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      loading: true,
    };
    this.fetchData = this.fetchData.bind(this);

    const columnHelper = createColumnHelper();
    this.columns = [
      columnHelper.accessor("user_name", {
        header: () => I18n.t("activerecord.attributes.user.user_name"),
      }),
      columnHelper.accessor("first_name", {
        header: () => I18n.t("activerecord.attributes.user.first_name"),
      }),
      columnHelper.accessor("last_name", {
        header: () => I18n.t("activerecord.attributes.user.last_name"),
      }),
      columnHelper.accessor("email", {
        header: () => I18n.t("activerecord.attributes.user.email"),
      }),
      columnHelper.accessor("hidden", {
        header: () => I18n.t("roles.active") + "?",
        filterFn: "equalsString",
        meta: {
          filterVariant: "select",
        },
      }),
      columnHelper.accessor("id", {
        id: "id",
        enableSorting: false,
        enableColumnFilter: false,
        header: () => I18n.t("actions"),
        cell: props => (
          <span>
            <a
              href={Routes.edit_course_ta_path(this.props.course_id, props.getValue())}
              aria-label={I18n.t("edit")}
              title={I18n.t("edit")}
            >
              <FontAwesomeIcon icon={faPencil} />
            </a>
            &nbsp;|&nbsp;
            <a
              href="#"
              onClick={() => this.removeTA(props.getValue())}
              aria-label={I18n.t("remove")}
              title={I18n.t("remove")}
            >
              <FontAwesomeIcon icon={faTrashCan} />
            </a>
          </span>
        ),
      }),
    ];
  }

  componentDidMount() {
    this.fetchData().then(data => this.setState({data: this.processData(data), loading: false}));
  }

  fetchData() {
    return fetch(Routes.course_tas_path(this.props.course_id), {
      headers: {
        Accept: "application/json",
      },
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(json => json.data);
  }

  processData(data) {
    data.forEach(row => (row.hidden = I18n.t(row.hidden ? "roles.inactive" : "roles.active")));
    return data;
  }

  removeTA = ta_id => {
    fetch(Routes.course_ta_path(this.props.course_id, ta_id), {
      method: "DELETE",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
      },
    })
      .then(response => {
        if (response.ok) {
          this.fetchData();
        }
      })
      .catch(error => {
        console.error("Error removing TA:", error);
      });
  };

  render() {
    return (
      <Table
        data={this.state.data}
        columns={this.columns}
        noDataText={I18n.t("tas.empty_table")}
        loading={this.state.loading}
      />
    );
  }
}

TATable.propTypes = {
  course_id: PropTypes.number,
};

function makeTATable(elem, props) {
  const root = createRoot(elem);
  root.render(<TATable {...props} />);
}

export {makeTATable, TATable};
