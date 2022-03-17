import React from "react";
import {render} from "react-dom";
import ReactTable from "react-table";

class AdminCourseList extends React.Component {
  constructor() {
    super();
    this.state = {
      courses: [
        {
          id: 1,
          name: "CSC108H1",
          display_name: "Introduction to Computer Programming",
          is_hidden: false,
        },
        {
          id: 2,
          name: "CSC148H1",
          display_name: "Introduction to Computer Science",
          is_hidden: true,
        },
        {
          id: 3,
          name: "CSC165H1",
          display_name: "Mathematical Expression and Reasoning for Computer Science",
          is_hidden: true,
        },
        {id: 4, name: "CSC207H1", display_name: "Software Design", is_hidden: true},
        {
          id: 5,
          name: "CSC209H1",
          display_name: "Software Tools and Systems Programming",
          is_hidden: true,
        },
        {
          id: 6,
          name: "CSC236H1",
          display_name: "Introduction to the Theory of Computation",
          is_hidden: true,
        },
        {id: 7, name: "CSC258H1", display_name: "Computer Organization", is_hidden: true},
        {id: 8, name: "CSC263H1", display_name: "Data Structures and Analysis", is_hidden: true},
      ],
      loading: false,
    };
  }

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
