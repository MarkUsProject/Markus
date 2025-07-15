import React from "react";
import {createRoot} from "react-dom/client";
import PropTypes from "prop-types";

import Table from "./table/table";
import {createColumnHelper} from "@tanstack/react-table";
import {faPencil} from "@fortawesome/free-solid-svg-icons";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

class InstructorTable extends React.Component {
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
          <a
            href={Routes.edit_course_instructor_path(this.props.course_id, props.getValue())}
            aria-label={I18n.t("edit")}
            title={I18n.t("edit")}
          >
            <FontAwesomeIcon icon={faPencil} />
          </a>
        ),
      }),
    ];
  }

  componentDidMount() {
    this.fetchData().then(data => this.setState({data: this.processData(data)}));
  }

  fetchData() {
    return fetch(Routes.course_instructors_path(this.props.course_id), {
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

  render() {
    return (
      <Table
        data={this.state.data}
        columns={this.columns}
        noDataText={I18n.t("instructors.empty_table")}
      />
    );
  }
}

InstructorTable.propTypes = {
  course_id: PropTypes.number,
};

function makeInstructorTable(elem, props) {
  const root = createRoot(elem);
  root.render(<InstructorTable {...props} />);
}

export {makeInstructorTable, InstructorTable};
