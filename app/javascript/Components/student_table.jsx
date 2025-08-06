import React from "react";
import {createRoot} from "react-dom/client";
import PropTypes from "prop-types";

import {CheckboxTable, withSelection} from "./markus_with_selection_hoc";
import {selectFilter} from "./Helpers/table_helpers";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import {faPencil, faTrashCan} from "@fortawesome/free-solid-svg-icons";

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
          selection: [],
          selectAll: false,
        });
      });
  };

  /* Called when an action is run */
  onSubmit = event => {
    event.preventDefault();

    const data = {
      student_ids: this.props.selection,
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

  render() {
    const {data, loading} = this.state;

    return (
      <div data-testid={"raw_student_table"}>
        <StudentsActionBox
          ref={r => (this.actionBox = r)}
          sections={data.sections}
          disabled={this.props.selection.length === 0}
          onSubmit={this.onSubmit}
          authenticity_token={this.props.authenticity_token}
        />
        <CheckboxTable
          ref={r => (this.checkboxTable = r)}
          data={data.students}
          columns={[
            {
              Header: I18n.t("activerecord.attributes.user.user_name"),
              accessor: "user_name",
              id: "user_name",
              minWidth: 120,
            },
            {
              Header: I18n.t("activerecord.attributes.user.first_name"),
              accessor: "first_name",
              minWidth: 120,
            },
            {
              Header: I18n.t("activerecord.attributes.user.last_name"),
              accessor: "last_name",
              minWidth: 120,
            },
            {
              Header: I18n.t("activerecord.attributes.user.email"),
              accessor: "email",
              minWidth: 150,
            },
            {
              Header: I18n.t("activerecord.attributes.user.id_number"),
              accessor: "id_number",
              minWidth: 90,
              className: "number",
            },
            {
              Header: I18n.t("activerecord.models.section", {count: 1}),
              accessor: "section",
              id: "section",
              Cell: ({value}) => {
                return data.sections[value] || "";
              },
              show: Boolean(data.sections),
              filterMethod: (filter, row) => {
                if (filter.value === "all") {
                  return true;
                } else {
                  return data.sections[row[filter.id]] === filter.value;
                }
              },
              Filter: selectFilter,
              filterOptions: Object.entries(data.sections).map(kv => ({
                value: kv[1],
                text: kv[1],
              })),
            },
            {
              Header: I18n.t("activerecord.attributes.user.grace_credits"),
              id: "grace_credits",
              accessor: "remaining_grace_credits",
              className: "number",
              Cell: row => `${row.value} / ${row.original.grace_credits}`,
              minWidth: 90,
              Filter: ({filter, onChange}) => (
                <input
                  onChange={event => onChange(event.target.valueAsNumber)}
                  type="number"
                  min={0}
                  value={filter ? filter.value : ""}
                />
              ),
              filterMethod: (filter, row) => {
                return (
                  isNaN(filter.value) || filter.value === row._original.remaining_grace_credits
                );
              },
            },
            {
              Header: I18n.t("roles.active") + "?",
              accessor: "hidden",
              Cell: ({value}) => (value ? I18n.t("roles.inactive") : I18n.t("roles.active")),
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
                  text: `${I18n.t("roles.active")} (${this.state.data.counts.active})`,
                },
                {
                  value: "inactive",
                  text: `${I18n.t("roles.inactive")} (${this.state.data.counts.inactive})`,
                },
              ],
              filterAllOptionText: `${I18n.t("all")} (${this.state.data.counts.all})`,
            },
            {
              Header: I18n.t("actions"),
              accessor: "_id",
              Cell: data => (
                <>
                  <span>
                    <a
                      href={Routes.edit_course_student_path(this.props.course_id, data.value)}
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
                      onClick={() => this.removeStudent(data.value)}
                      aria-label={I18n.t("remove")}
                      title={I18n.t("remove")}
                    >
                      <FontAwesomeIcon icon={faTrashCan} />
                    </a>
                  </span>
                </>
              ),
              sortable: false,
              filterable: false,
            },
          ]}
          defaultSorted={[
            {
              id: "user_name",
            },
          ]}
          filterable
          loading={loading}
          noDataText={this.state.loading ? null : I18n.t("instructors.empty_table")}
          {...this.props.getCheckboxProps()}
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
  selection: PropTypes.array.isRequired,
  authenticity_token: PropTypes.string,
  getCheckboxProps: PropTypes.func.isRequired,
};

let StudentTable = withSelection(RawStudentTable);

function makeStudentTable(elem, props) {
  const root = createRoot(elem);
  root.render(<StudentTable {...props} />);
}

export {StudentTable, StudentsActionBox, makeStudentTable};
