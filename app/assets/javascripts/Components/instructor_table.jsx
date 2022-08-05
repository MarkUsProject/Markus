import React from "react";
import {render} from "react-dom";
import PropTypes from "prop-types";

import ReactTable from "react-table";

class InstructorTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
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
      this.setState({data: res, loading: false});
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
