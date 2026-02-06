import React from "react";
import {createRoot} from "react-dom/client";
import PropTypes from "prop-types";

import Table from "./table/table";
import {createColumnHelper} from "@tanstack/react-table";
import {selectFilter} from "./Helpers/table_helpers";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import {faPencil, faTrashCan} from "@fortawesome/free-solid-svg-icons";

const columnHelper = createColumnHelper();

class RawStudentTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: {
        students: [],
        sections: {},
        counts: {all: 0, active: 0, inactive: 0},
      },
      loading: true,
      rowSelection: {},
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(Routes.course_students_path(this.props.course_id), {
      headers: {
        Accept: "application/json",
      },
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(res => {
        this.setState({
          data: res,
          loading: false,
        });
      });
  };

  /* Called when an action is run */
  onSubmit = event => {
    event.preventDefault();

    // Convert rowSelection object to array of student IDs
    const selectedIds = Object.keys(this.state.rowSelection).filter(
      key => this.state.rowSelection[key]
    );

    const data = {
      student_ids: selectedIds,
      bulk_action: this.actionBox.state.action,
      grace_credits: this.actionBox.state.grace_credits,
      section: this.actionBox.state.section,
    };

    this.setState({loading: true});
    $.ajax({
      method: "patch",
      url: Routes.bulk_modify_course_students_path(this.props.course_id),
      data: data,
    }).then(this.fetchData);
  };

  removeStudent = student_id => {
    fetch(Routes.course_student_path(this.props.course_id, student_id), {
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
        console.error("Error removing student:", error);
      });
  };

  getColumns = () => {
    const {data} = this.state;

    return [
      columnHelper.accessor("user_name", {
        header: I18n.t("activerecord.attributes.user.user_name"),
        id: "user_name",
        minSize: 120,
      }),
      columnHelper.accessor("first_name", {
        header: I18n.t("activerecord.attributes.user.first_name"),
        minSize: 120,
      }),
      columnHelper.accessor("last_name", {
        header: I18n.t("activerecord.attributes.user.last_name"),
        minSize: 120,
      }),
      columnHelper.accessor("email", {
        header: I18n.t("activerecord.attributes.user.email"),
        minSize: 150,
      }),
      columnHelper.accessor("id_number", {
        header: I18n.t("activerecord.attributes.user.id_number"),
        minSize: 90,
        meta: {
          className: "number",
        },
      }),
      columnHelper.accessor("section", {
        header: I18n.t("activerecord.models.section", {count: 1}),
        id: "section",
        cell: ({getValue}) => {
          const value = getValue();
          return data.sections[value] || "";
        },
        enableColumnFilter: Boolean(data.sections),
        filterFn: (row, columnId, filterValue) => {
          if (filterValue === "all") {
            return true;
          } else {
            return data.sections[row.getValue(columnId)] === filterValue;
          }
        },
        meta: {
          filterVariant: "select",
          filterOptions: Object.entries(data.sections).map(kv => ({
            value: kv[1],
            text: kv[1],
          })),
        },
      }),
      columnHelper.accessor("remaining_grace_credits", {
        header: I18n.t("activerecord.attributes.user.grace_credits"),
        id: "grace_credits",
        cell: ({getValue, row}) => {
          return `${getValue()} / ${row.original.grace_credits}`;
        },
        minSize: 90,
        filterFn: (row, columnId, filterValue) => {
          if (isNaN(filterValue)) {
            return true;
          }
          return row.getValue(columnId) === filterValue;
        },
        meta: {
          className: "number",
          filterVariant: "number",
        },
      }),
      columnHelper.accessor("hidden", {
        header: I18n.t("roles.active") + "?",
        cell: ({getValue}) => {
          const value = getValue();
          return value ? I18n.t("roles.inactive") : I18n.t("roles.active");
        },
        filterFn: (row, columnId, filterValue) => {
          if (filterValue === "all") {
            return true;
          } else {
            return (
              (filterValue === "active" && !row.getValue(columnId)) ||
              (filterValue === "inactive" && row.getValue(columnId))
            );
          }
        },
        meta: {
          filterVariant: "select",
          filterOptions: [
            {
              value: "active",
              text: `${I18n.t("roles.active")} (${this.state.data.counts.active})`,
            },
            {
              value: "inactive",
              text: `${I18n.t("roles.inactive")} (${this.state.data.counts.inactive})`,
            },
          ],
          filterAllOptionText: `${I18n.t("all")} (${this.state.data.counts.all})`,
        },
      }),
      columnHelper.accessor("_id", {
        header: I18n.t("actions"),
        cell: ({getValue}) => {
          const id = getValue();

          return (
            <>
              <span>
                <a
                  href={Routes.edit_course_student_path(this.props.course_id, id)}
                  aria-label={I18n.t("edit")}
                  title={I18n.t("edit")}
                >
                  <FontAwesomeIcon icon={faPencil} />
                </a>
              </span>
              &nbsp;|&nbsp;
              <span>
                <a
                  href="#"
                  onClick={() => this.removeStudent(id)}
                  aria-label={I18n.t("remove")}
                  title={I18n.t("remove")}
                >
                  <FontAwesomeIcon icon={faTrashCan} />
                </a>
              </span>
            </>
          );
        },
        enableSorting: false,
        enableColumnFilter: false,
      }),
    ];
  };

  render() {
    const {data, loading, rowSelection} = this.state;
    const selectedCount = Object.keys(rowSelection).filter(key => rowSelection[key]).length;

    return (
      <div data-testid={"raw_student_table"}>
        <StudentsActionBox
          ref={r => (this.actionBox = r)}
          sections={data.sections}
          disabled={selectedCount === 0}
          onSubmit={this.onSubmit}
          authenticity_token={this.props.authenticity_token}
        />
        <Table
          loading={loading}
          data={data.students}
          columns={this.getColumns()}
          enableRowSelection={true}
          rowSelection={rowSelection}
          onRowSelectionChange={updater => {
            this.setState(prevState => ({
              rowSelection:
                typeof updater === "function" ? updater(prevState.rowSelection) : updater,
            }));
          }}
          getRowId={row => row._id}
          initialState={{
            sorting: [
              {
                id: "user_name",
              },
            ],
          }}
          noDataText={I18n.t("students.empty_table")}
        />
      </div>
    );
  }
}

class StudentsActionBox extends React.Component {
  constructor() {
    super();
    this.state = {
      action: "give_grace_credits",
      grace_credits: 0,
      selected_section: "",
      button_disabled: false,
    };
  }

  inputChanged = event => {
    this.setState({[event.target.name]: event.target.value});
  };

  actionChanged = event => {
    this.setState({action: event.target.value});
  };

  render = () => {
    let optionalInputBox = null;
    if (this.state.action === "give_grace_credits") {
      optionalInputBox = (
        <input
          type="number"
          name="grace_credits"
          value={this.state.grace_credits}
          onChange={this.inputChanged}
        />
      );
    } else if (this.state.action === "update_section") {
      if (Object.keys(this.props.sections).length > 0) {
        const section_options = Object.entries(this.props.sections).map(section => (
          <option key={section[0]} value={section[0]}>
            {section[1]}
          </option>
        ));
        optionalInputBox = (
          <select
            name="section"
            value={this.state.section}
            onChange={this.inputChanged}
            data-testid={"student_action_box_update_section"}
          >
            <option key={"none"} value={""}>
              {I18n.t("students.instructor_actions.no_section")}
            </option>
            {section_options}
          </select>
        );
      } else {
        optionalInputBox = <span>{I18n.t("sections.none")}</span>;
      }
    }

    return (
      <form onSubmit={this.props.onSubmit} data-testid={"student_action_box"}>
        <select
          value={this.state.action}
          onChange={this.actionChanged}
          data-testid={"student_action_box_select"}
        >
          <option value="give_grace_credits">
            {I18n.t("students.instructor_actions.give_grace_credits")}
          </option>
          <option value="update_section">
            {I18n.t("students.instructor_actions.update_section")}
          </option>
          <option value="hide">{I18n.t("students.instructor_actions.mark_inactive")}</option>
          <option value="unhide">{I18n.t("students.instructor_actions.mark_active")}</option>
        </select>
        {optionalInputBox}
        <input type="submit" disabled={this.props.disabled} value={I18n.t("apply")} />
        <input type="hidden" name="authenticity_token" value={this.props.authenticity_token} />
      </form>
    );
  };
}

StudentsActionBox.propTypes = {
  onSubmit: PropTypes.func,
  disabled: PropTypes.bool,
  authenticity_token: PropTypes.string,
  sections: PropTypes.object,
};

RawStudentTable.propTypes = {
  course_id: PropTypes.number,
  // selection: PropTypes.array.isRequired,   TODO: delete these?
  authenticity_token: PropTypes.string,
  // getCheckboxProps: PropTypes.func.isRequired, TODO
};

// let StudentTable = withSelection(RawStudentTable); TODO

function makeStudentTable(elem, props) {
  const root = createRoot(elem);
  // root.render(<StudentTable {...props} />); TODO
  root.render(<RawStudentTable {...props} />);
}

// export {StudentTable, StudentsActionBox, makeStudentTable}; TODO
export {RawStudentTable as StudentTable, StudentsActionBox, makeStudentTable};
