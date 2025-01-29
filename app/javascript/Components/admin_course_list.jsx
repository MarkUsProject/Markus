import React from "react";
import {createRoot} from "react-dom/client";
import ReactTable from "react-table";
import {selectFilter} from "./Helpers/table_helpers";

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
    fetch(Routes.admin_courses_path(), {
      headers: {
        Accept: "application/json",
      },
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(data => {
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
      Header: I18n.t("activerecord.attributes.course.is_hidden"),
      accessor: "is_hidden",
      minWidth: 70,
      Cell: ({value}) => {
        return value ? I18n.t("courses.hidden") : I18n.t("courses.visible");
      },
      filterMethod: (filter, row) => {
        if (filter.value === "all") {
          return true;
        } else {
          return filter.value === row[filter.id].toString();
        }
      },
      Filter: selectFilter,
      filterOptions: [
        {
          text: I18n.t("courses.hidden"),
          value: true,
        },
        {
          text: I18n.t("courses.visible"),
          value: false,
        },
      ],
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
            <a href={Routes.course_path(value)}>{I18n.t("courses.go_to_course")}</a>
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
  const root = createRoot(elem);
  root.render(<AdminCourseList {...props} />);
}
