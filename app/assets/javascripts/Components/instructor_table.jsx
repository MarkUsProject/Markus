import React from "react";
import {render} from "react-dom";
import PropTypes from "prop-types";

import ReactTable from "react-table";
import {selectFilter} from "./Helpers/table_helpers";

class InstructorTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      counts: {all: 0, active: 0, inactive: 0},
      loading: true,
    };
    this.fetchData = this.fetchData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    $.ajax({
      url: Routes.course_instructors_path(this.props.course_id),
      dataType: "json",
    }).then(res => {
      this.setState({data: res.data, counts: res.counts, loading: false});
    });
  }

  render() {
    const {data} = this.state;
    return (
      <ReactTable
        data={data}
        columns={[
          {
            Header: I18n.t("activerecord.attributes.user.user_name"),
            accessor: "user_name",
          },
          {
            Header: I18n.t("activerecord.attributes.user.first_name"),
            accessor: "first_name",
          },
          {
            Header: I18n.t("activerecord.attributes.user.last_name"),
            accessor: "last_name",
          },
          {
            Header: I18n.t("activerecord.attributes.user.email"),
            accessor: "email",
          },
          {
            Header: I18n.t("students.active") + "?",
            accessor: "hidden",
            Cell: ({value}) => (value ? I18n.t("students.inactive") : I18n.t("students.active")),
            filterMethod: (filter, row) => {
              if (filter.value === "all") {
                return true;
              } else {
                return (
                  (filter.value === "active" && !row[filter.id]) ||
                  (filter.value === "inactive" && row[filter.id])
                );
              }
            },
            Filter: selectFilter,
            filterOptions: [
              {
                value: "active",
                text: `${I18n.t("students.active")} (${this.state.counts.active})`,
              },
              {
                value: "inactive",
                text: `${I18n.t("students.inactive")} (${this.state.counts.inactive})`,
              },
            ],
            filterAllOptionText: `${I18n.t("all")} (${this.state.counts.all})`,
          },
          {
            Header: I18n.t("actions"),
            accessor: "id",
            Cell: data => (
              <span>
                <a href={Routes.edit_course_instructor_path(this.props.course_id, data.value)}>
                  {I18n.t("edit")}
                </a>
              </span>
            ),
            sortable: false,
          },
        ]}
        filterable
        loading={this.state.loading}
      />
    );
  }
}

InstructorTable.propTypes = {
  course_id: PropTypes.number,
};

function makeInstructorTable(elem, props) {
  render(<InstructorTable {...props} />, elem);
}

export {makeInstructorTable, InstructorTable};
