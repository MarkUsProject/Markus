import React from "react";
import {render} from "react-dom";
import ReactTable from "react-table";

class AdminCourseList extends React.Component {
  constructor() {
    super();
    this.state = {
      courses: [],
      loading: true,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    $.ajax({
      url: Routes.admin_courses_path(),
      dataType: "json",
    }).then(data => {
      this.setState({courses: data, loading: false});
    });
  };

  columns = [
    {
      Header: I18n.t("activerecord.attributes.course.name"),
      accessor: "name",
      minWidth: 70,
    },
    {
      Header: I18n.t("activerecord.attributes.course.display_name"),
      accessor: "display_name",
      minWidth: 120,
    },
    {
      Header: I18n.t("actions"),
      accessor: "id",
      minWidth: 70,
      Cell: ({value}) => {
        return (
          <span>
            <a href={Routes.edit_admin_course_path(value)}>{I18n.t("edit")}</a>
            &nbsp;|&nbsp;
            <a href={Routes.course_path(value)}>{I18n.t("view")}</a>
          </span>
        );
      },
      sortable: false,
      filterable: false,
    },
  ];

  render() {
    return (
      <ReactTable
        data={this.state.courses}
        columns={this.columns}
        filterable
        defaultSorted={[{id: "name"}]}
        loading={this.state.loading}
      />
    );
  }
}

export function makeAdminCourseList(elem, props) {
  render(<AdminCourseList {...props} />, elem);
}
