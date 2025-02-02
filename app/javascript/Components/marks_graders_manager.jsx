import React from "react";
import {createRoot} from "react-dom/client";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

import {withSelection, CheckboxTable} from "./markus_with_selection_hoc";

class MarksGradersManager extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      graders: [],
      students: [],
      loading: true,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(
      Routes.course_grade_entry_form_marks_graders_path(
        this.props.course_id,
        this.props.grade_entry_form_id
      ),
      {
        headers: {
          Accept: "application/json",
        },
      }
    )
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(res => {
        this.studentsTable.resetSelection();
        this.gradersTable.resetSelection();
        this.setState({
          graders: res.graders,
          students: res.students || [],
          loading: false,
        });
      });
  };

  assignAll = () => {
    let students = this.studentsTable.state.selection;
    let graders = this.gradersTable.state.selection;

    if (students.length === 0) {
      alert(I18n.t("groups.select_a_student"));
      return;
    }

    if (graders.length === 0) {
      alert(I18n.t("graders.select_a_grader"));
      return;
    }

    $.post({
      url: Routes.assign_all_course_grade_entry_form_marks_graders_path(
        this.props.course_id,
        this.props.grade_entry_form_id
      ),
      data: {
        students: students,
        graders: graders,
      },
    }).then(this.fetchData);
  };

  unassignAll = () => {
    let students = this.studentsTable.state.selection;
    let graders = this.gradersTable.state.selection;

    if (students.length === 0) {
      alert(I18n.t("groups.select_a_student"));
      return;
    }

    if (graders.length === 0) {
      alert(I18n.t("graders.select_a_grader"));
      return;
    }

    $.post({
      url: Routes.unassign_all_course_grade_entry_form_marks_graders_path(
        this.props.course_id,
        this.props.grade_entry_form_id
      ),
      data: {
        students: students,
        graders: graders,
      },
    }).then(this.fetchData);
  };

  unassignSingle = (student_id, grader_user_name) => {
    $.post({
      url: Routes.unassign_single_course_grade_entry_form_marks_graders_path(
        this.props.course_id,
        this.props.grade_entry_form_id
      ),
      data: {
        student_id: student_id,
        grader_user_name: grader_user_name,
      },
    }).then(this.fetchData);
  };

  assignRandomly = () => {
    let students = this.studentsTable.state.selection;
    let graders = this.gradersTable.state.selection;

    if (students.length === 0) {
      alert(I18n.t("groups.select_a_student"));
      return;
    }

    if (graders.length === 0) {
      alert(I18n.t("graders.select_a_grader"));
      return;
    }

    $.post({
      url: Routes.randomly_assign_course_grade_entry_form_marks_graders_path(
        this.props.course_id,
        this.props.grade_entry_form_id
      ),
      data: {
        students: students,
        graders: graders,
      },
    }).then(this.fetchData);
  };

  render() {
    return (
      <div>
        <GradersActionBox
          assignAll={this.assignAll}
          assignRandomly={this.assignRandomly}
          unassignAll={this.unassignAll}
        />
        <div className="mapping-tables">
          <div className="mapping-table">
            <GradersTable
              ref={r => (this.gradersTable = r)}
              graders={this.state.graders}
              loading={this.state.loading}
            />
          </div>
          <div className="mapping-table">
            <MarksStudentsTable
              ref={r => (this.studentsTable = r)}
              students={this.state.students}
              loading={this.state.loading}
              unassignSingle={this.unassignSingle}
              showSections={this.props.showSections}
            />
          </div>
        </div>
      </div>
    );
  }
}

class RawGradersTable extends React.Component {
  columns = [
    {
      show: false,
      accessor: "_id",
      id: "_id",
    },
    {
      Header: I18n.t("activerecord.attributes.user.user_name"),
      accessor: "user_name",
      id: "user_name",
    },
    {
      Header: I18n.t("activerecord.attributes.user.full_name"),
      Cell: row => `${row.original.first_name} ${row.original.last_name}`,
      minWidth: 170,
      filterMethod: (filter, row) => {
        if (filter.value) {
          if (
            row._original.first_name.includes(filter.value) ||
            row._original.last_name.includes(filter.value)
          ) {
            return true;
          }
        } else {
          return true;
        }
      },
    },
    {
      Header: I18n.t("activerecord.models.student.other"),
      accessor: "students",
      className: "number",
      filterable: false,
    },
  ];

  render() {
    return (
      <CheckboxTable
        ref={r => (this.checkboxTable = r)}
        data={this.props.graders}
        columns={this.columns}
        defaultSorted={[
          {
            id: "user_name",
          },
        ]}
        loading={this.props.loading}
        filterable
        {...this.props.getCheckboxProps()}
      />
    );
  }
}

class RawMarksStudentsTable extends React.Component {
  getColumns = () => {
    return [
      {
        show: false,
        accessor: "_id",
        id: "_id",
      },
      {
        show: this.props.showSections,
        Header: I18n.t("activerecord.models.section.one"),
        accessor: "section",
        minWidth: 70,
      },
      {
        Header: I18n.t("activerecord.attributes.user.user_name"),
        accessor: "user_name",
        id: "user_name",
      },
      {
        Header: I18n.t("activerecord.attributes.user.full_name"),
        Cell: row => `${row.original.first_name} ${row.original.last_name}`,
        minWidth: 170,
        filterMethod: (filter, row) => {
          if (filter.value) {
            if (
              row._original.first_name.includes(filter.value) ||
              row._original.last_name.includes(filter.value)
            ) {
              return true;
            }
          } else {
            return true;
          }
        },
      },
      {
        Header: I18n.t("activerecord.models.ta.other"),
        accessor: "graders",
        Cell: row => {
          return row.value.map(ta => (
            <div key={`${row.original._id}-${ta}`}>
              {ta}
              <a
                href="#"
                onClick={() => this.props.unassignSingle(row.original._id, ta)}
                title={I18n.t("graders.actions.unassign_grader")}
              >
                <FontAwesomeIcon icon="fa-solid fa-trash" className="icon-right" />
              </a>
            </div>
          ));
        },
        filterable: false,
      },
    ];
  };

  render() {
    return (
      <CheckboxTable
        ref={r => (this.checkboxTable = r)}
        data={this.props.students}
        columns={this.getColumns()}
        defaultSorted={[
          {
            id: "user_name",
          },
        ]}
        loading={this.props.loading}
        filterable
        {...this.props.getCheckboxProps()}
      />
    );
  }
}

const GradersTable = withSelection(RawGradersTable);
const MarksStudentsTable = withSelection(RawMarksStudentsTable);

class GradersActionBox extends React.Component {
  render = () => {
    return (
      <div className="rt-action-box">
        <button onClick={this.props.assignAll}>
          <FontAwesomeIcon icon="fa-solid fa-user-plus" />
          {I18n.t("graders.actions.assign_grader")}
        </button>
        <button onClick={this.props.assignRandomly}>
          <FontAwesomeIcon icon="fa-solid fa-dice" />
          {I18n.t("graders.actions.randomly_assign_graders")}
        </button>
        <button onClick={this.props.unassignAll}>
          <FontAwesomeIcon icon="fa-solid fa-user-minus" />
          {I18n.t("graders.actions.unassign_grader")}
        </button>
      </div>
    );
  };
}

export function makeMarksGradersManager(elem, props) {
  const root = createRoot(elem);
  root.render(<MarksGradersManager {...props} />);
}
