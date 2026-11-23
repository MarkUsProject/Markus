import React from "react";
import {createRoot} from "react-dom/client";
import Table from "./table/table";
import {createColumnHelper} from "@tanstack/react-table";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import {faPencil} from "@fortawesome/free-solid-svg-icons";

const columnHelper = createColumnHelper();
export class AdminCourseList extends React.Component {
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
        const courses = data.map(course => ({
          ...course,
          is_hidden: course.is_hidden ? I18n.t("courses.hidden") : I18n.t("courses.visible"),
        }));
        this.setState({courses, loading: false});
      });
  };

  columns = [
    columnHelper.accessor("name", {
      header: () => I18n.t("activerecord.attributes.course.name"),
      minSize: 70,
    }),
    columnHelper.accessor("display_name", {
      header: () => I18n.t("activerecord.attributes.course.display_name"),
      minSize: 120,
    }),
    columnHelper.accessor("is_hidden", {
      header: () => I18n.t("activerecord.attributes.course.is_hidden"),
      minSize: 70,
      filterFn: "equalsString",
      meta: {
        filterVariant: "select",
      },
    }),
    columnHelper.accessor("id", {
      header: () => I18n.t("actions"),
      minSize: 70,
      cell: info => {
        const value = info.getValue();
        return (
          <span>
            <a
              href={Routes.edit_admin_course_path(value)}
              aria-label={I18n.t("edit")}
              title={I18n.t("edit")}
            >
              <FontAwesomeIcon icon={faPencil} />
            </a>
            &nbsp;|&nbsp;
            <a href={Routes.course_path(value)}>{I18n.t("courses.go_to_course")}</a>
          </span>
        );
      },
      enableSorting: false,
      enableColumnFilter: false,
    }),
  ];

  render() {
    return (
      <Table
        data={this.state.courses}
        columns={this.columns}
        initialState={{sorting: [{id: "name", desc: false}]}}
        loading={this.state.loading}
      />
    );
  }
}

export function makeAdminCourseList(elem, props) {
  const root = createRoot(elem);
  root.render(<AdminCourseList {...props} />);
}
