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
      url: Routes.api_courses_path(),
      dataType: "json",
      headers: {
        Authorization: `MarkUsAuth ${this.props.apiKey}`,
      },
    }).then(data => {
      this.setState({courses: data, loading: false});
    });
  };

  columns = [
    {
      Header: "Name",
      accessor: "name",
      minWidth: 70,
    },
    {
      Header: "Display Name",
      accessor: "display_name",
      minWidth: 120,
    },
    {
      Header: I18n.t("actions"),
      accessor: "id",
      minWidth: 70,
      Cell: ({value}) => {
        return (
          <a href="#" onClick={() => {}}>
            {I18n.t("edit")}
          </a>
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
