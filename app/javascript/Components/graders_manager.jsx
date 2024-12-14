import React from "react";
import {render} from "react-dom";
import {Tab, Tabs, TabList, TabPanel} from "react-tabs";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

import {withSelection, CheckboxTable} from "./markus_with_selection_hoc";
import {selectFilter} from "./Helpers/table_helpers";
import {GraderDistributionModal} from "./Modals/graders_distribution_modal";
import {SectionDistributionModal} from "./Modals/section_distribution_modal";

class GradersManager extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      graders: [],
      groups: [],
      criteria: [],
      assign_graders_to_criteria: false,
      loading: true,
      tableName: "groups_table", // The first tab
      skip_empty_submissions: true,
      anonymize_groups: false,
      hide_unassigned_criteria: false,
      sections: {},
      isGraderDistributionModalOpen: false,
      isSectionDistributionModalOpen: false,
      show_hidden: false,
      show_hidden_groups: false,
      hidden_graders_count: 0,
      inactive_groups_count: 0,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  openGraderDistributionModal = () => {
    let groups = this.groupsTable ? this.groupsTable.state.selection : [];
    let criteria = this.criteriaTable ? this.criteriaTable.state.selection : [];
    let graders = this.gradersTable.state.selection;
    if (groups.length === 0 && criteria.length === 0) {
      alert(I18n.t("groups.select_a_group"));
      return;
    }

    if (graders.length === 0) {
      alert(I18n.t("graders.select_a_grader"));
      return;
    }

    this.setState({
      isGraderDistributionModalOpen: true,
    });
  };
  openSectionDistributionModal = () => {
    this.setState({
      isSectionDistributionModalOpen: true,
    });
  };

  fetchData = () => {
    fetch(Routes.course_assignment_graders_path(this.props.course_id, this.props.assignment_id), {
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
        if (this.gradersTable) this.gradersTable.resetSelection();
        if (this.groupsTable) this.groupsTable.resetSelection();
        if (this.criteriaTable) this.criteriaTable.resetSelection();

        let inactive_groups_count = 0;
        res.groups.forEach(group => {
          if (group.members.length && group.members.every(member => member[2])) {
            group.inactive = true;
            inactive_groups_count += 1;
          } else {
            group.inactive = false;
          }
        });
        this.setState({
          graders: res.graders,
          groups: res.groups,
          criteria: res.criteria,
          assign_graders_to_criteria: res.assign_graders_to_criteria,
          loading: false,
          sections: res.sections,
          anonymize_groups: res.anonymize_groups,
          hide_unassigned_criteria: res.hide_unassigned_criteria,
          isGraderDistributionModalOpen: false,
          isSectionDistributionModalOpen: false,
          hidden_graders_count: res.graders.filter(grader => grader.hidden).length,
          inactive_groups_count: inactive_groups_count,
        });
      });
  };

  assignAll = () => {
    let groups = this.groupsTable ? this.groupsTable.state.selection : [];
    let criteria = this.criteriaTable ? this.criteriaTable.state.selection : [];
    let graders = this.gradersTable.state.selection;

    if (groups.length === 0 && criteria.length === 0) {
      alert(I18n.t("groups.select_a_group"));
      return;
    }

    if (graders.length === 0) {
      alert(I18n.t("graders.select_a_grader"));
      return;
    }

    $.post({
      url: Routes.global_actions_course_assignment_graders_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {
        global_actions: "assign",
        current_table: this.state.tableName,
        skip_empty_submissions: this.state.skip_empty_submissions,
        groupings: groups,
        criteria: criteria,
        graders: graders,
      },
    }).then(this.fetchData);
  };

  assignSections = assignments => {
    let sections = Object.keys(assignments);
    let graders = Object.values(assignments);
    $.post({
      url: Routes.global_actions_course_assignment_graders_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {
        global_actions: "assign_sections",
        current_table: this.state.tableName,
        skip_empty_submissions: this.state.skip_empty_submissions,
        assignments: assignments,
        sections: sections,
        graders: graders,
      },
    }).then(this.fetchData);
  };

  assignRandomly = weightings => {
    let groups = this.groupsTable ? this.groupsTable.state.selection : [];
    let criteria = this.criteriaTable ? this.criteriaTable.state.selection : [];
    let graders = Object.keys(weightings);
    let weights = Object.values(weightings);

    $.post({
      url: Routes.global_actions_course_assignment_graders_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {
        global_actions: "random_assign",
        current_table: this.state.tableName,
        skip_empty_submissions: this.state.skip_empty_submissions,
        groupings: groups,
        criteria: criteria,
        graders: graders,
        weightings: weights,
      },
    }).then(this.fetchData);
  };

  unassignAll = () => {
    let groups = this.groupsTable ? this.groupsTable.state.selection : [];
    let criteria = this.criteriaTable ? this.criteriaTable.state.selection : [];
    let graders = this.gradersTable.state.selection;

    if (groups.length === 0 && criteria.length === 0) {
      alert(I18n.t("groups.select_a_group"));
      return;
    }

    if (graders.length === 0) {
      alert(I18n.t("graders.select_a_grader"));
      return;
    }

    $.post({
      url: Routes.global_actions_course_assignment_graders_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {
        global_actions: "unassign",
        current_table: this.state.tableName,
        groupings: groups,
        criteria: criteria,
        graders: graders,
      },
    }).then(this.fetchData);
  };

  unassignSingle = (id, grader_user_name, origin) => {
    let groups, criteria;
    if (origin === "groups_table") {
      groups = [id];
      criteria = [];
    } else {
      groups = [];
      criteria = [id];
    }

    $.post({
      url: Routes.global_actions_course_assignment_graders_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {
        global_actions: "unassign",
        current_table: origin,
        groupings: groups,
        criteria: criteria,
        grader_user_names: [grader_user_name],
      },
    }).then(this.fetchData);
  };

  toggleSkipEmptySubmissions = () => {
    this.setState({
      skip_empty_submissions: !this.state.skip_empty_submissions,
    });
  };

  toggleAssignGradersToCriteria = () => {
    const assign = !this.state.assign_graders_to_criteria;
    $.post({
      url: Routes.set_boolean_graders_options_course_assignment_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {
        attribute: {
          assignment_properties_attributes: {
            assign_graders_to_criteria: assign,
          },
        },
      },
    }).then(() => this.setState({assign_graders_to_criteria: assign}));
  };

  toggleAnonymizeGroups = () => {
    const assign = !this.state.anonymize_groups;
    $.post({
      url: Routes.set_boolean_graders_options_course_assignment_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {
        attribute: {
          assignment_properties_attributes: {anonymize_groups: assign},
        },
      },
    }).then(() => this.setState({anonymize_groups: assign}));
  };

  toggleHideUnassignedCriteria = () => {
    const assign = !this.state.hide_unassigned_criteria;
    $.post({
      url: Routes.set_boolean_graders_options_course_assignment_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {
        attribute: {
          assignment_properties_attributes: {
            hide_unassigned_criteria: assign,
          },
        },
      },
    }).then(() => this.setState({hide_unassigned_criteria: assign}));
  };

  getAssignedGraderObjects = () => {
    return this.state.graders.filter(grader => {
      return this.gradersTable.state.selection.includes(grader._id);
    });
  };

  renderHideUnassignedCriteria = () => {
    if (this.state.assign_graders_to_criteria) {
      return (
        <div style={{marginBottom: "1em"}}>
          <label>
            <input
              type="checkbox"
              checked={this.state.hide_unassigned_criteria}
              onChange={this.toggleHideUnassignedCriteria}
              style={{marginRight: "5px"}}
            />
            {I18n.t("graders.hide_unassigned_criteria")}
          </label>
        </div>
      );
    }
  };

  onSelectTable = index => {
    if (index === 0) {
      this.setState({tableName: "groups_table"});
    } else {
      this.setState({tableName: "criteria_table"});
    }
  };

  toggleShowHidden = event => {
    let show_hidden = event.target.checked;
    this.setState({show_hidden});
  };

  toggleShowHiddenGroups = event => {
    let show_hidden_groups = event.target.checked;
    this.setState({show_hidden_groups});
  };

  render() {
    return (
      <div>
        <GradersActionBox
          assignAll={this.assignAll}
          openGraderDistributionModal={this.openGraderDistributionModal}
          openSectionDistributionModal={this.openSectionDistributionModal}
          unassignAll={this.unassignAll}
          showHidden={this.state.show_hidden}
          showHiddenGroups={this.state.show_hidden_groups}
          updateShowHidden={this.toggleShowHidden}
          updateShowHiddenGroups={this.toggleShowHiddenGroups}
          hiddenGradersCount={this.state.loading ? null : this.state.hidden_graders_count}
          hiddenGroupsCount={this.state.loading ? null : this.state.inactive_groups_count}
        />
        <div className="mapping-tables">
          <div className="mapping-table">
            <GradersTable
              ref={r => (this.gradersTable = r)}
              graders={this.state.graders}
              loading={this.state.loading}
              assign_graders_to_criteria={this.state.assign_graders_to_criteria}
              numCriteria={this.state.criteria.length}
              showHidden={this.state.show_hidden}
            />
          </div>
          <div className="mapping-table">
            <Tabs onSelect={this.onSelectTable}>
              <TabList>
                <Tab>{I18n.t("activerecord.models.group.other")}</Tab>
                <Tab>{I18n.t("activerecord.models.criterion.other")}</Tab>
              </TabList>

              <TabPanel>
                <div style={{marginBottom: "1em"}}>
                  <label>
                    <input
                      type="checkbox"
                      checked={!this.state.skip_empty_submissions}
                      onChange={this.toggleSkipEmptySubmissions}
                      style={{marginRight: "5px"}}
                    />
                    {I18n.t("graders.skip_empty_submissions")}
                  </label>
                  <div className="inline-help">
                    <p>{I18n.t("graders.skip_empty_submissions_tooltip")}</p>
                  </div>
                </div>
                <div style={{marginBottom: "1em"}}>
                  <label>
                    <input
                      type="checkbox"
                      checked={this.state.anonymize_groups}
                      onChange={this.toggleAnonymizeGroups}
                      style={{marginRight: "5px"}}
                    />
                    {I18n.t("graders.anonymize_groups")}
                  </label>
                </div>
                <GroupsTable
                  ref={r => (this.groupsTable = r)}
                  groups={this.state.groups}
                  loading={this.state.loading}
                  unassignSingle={this.unassignSingle}
                  showSections={this.props.showSections}
                  sections={this.state.sections}
                  numCriteria={this.state.criteria.length}
                  showCoverage={this.state.assign_graders_to_criteria}
                  showInactive={this.state.show_hidden_groups}
                />
              </TabPanel>
              <TabPanel>
                <div style={{marginBottom: "1em"}}>
                  <label>
                    <input
                      type="checkbox"
                      onChange={this.toggleAssignGradersToCriteria}
                      checked={this.state.assign_graders_to_criteria}
                      style={{marginRight: "5px"}}
                    />
                    {I18n.t("graders.assign_to_criteria")}
                  </label>
                </div>
                {this.renderHideUnassignedCriteria()}
                <CriteriaTable
                  display={this.state.assign_graders_to_criteria}
                  ref={r => (this.criteriaTable = r)}
                  criteria={this.state.criteria}
                  loading={this.state.loading}
                  unassignSingle={this.unassignSingle}
                  numGroups={this.state.groups.length}
                />
              </TabPanel>
            </Tabs>
          </div>
        </div>
        {this.state.isGraderDistributionModalOpen && (
          <GraderDistributionModal
            isOpen={this.state.isGraderDistributionModalOpen}
            onRequestClose={() =>
              this.setState({
                isGraderDistributionModalOpen: false,
              })
            }
            graders={this.getAssignedGraderObjects()}
            onSubmit={this.assignRandomly}
          />
        )}
        {this.state.isSectionDistributionModalOpen && (
          <SectionDistributionModal
            isOpen={this.state.isSectionDistributionModalOpen}
            onRequestClose={() => this.setState({isSectionDistributionModalOpen: false})}
            onSubmit={this.assignSections}
            graders={this.state.graders}
            sections={this.state.sections}
          />
        )}
      </div>
    );
  }
}

class RawGradersTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      filtered: [],
    };
  }

  getColumns = () => [
    {
      accessor: "hidden",
      id: "hidden",
      width: 0,
      className: "rt-hidden",
      headerClassName: "rt-hidden",
      resizable: false,
    },
    {
      show: false,
      accessor: "_id",
      id: "_id",
    },
    {
      Header: I18n.t("activerecord.attributes.user.user_name"),
      accessor: "user_name",
      id: "user_name",
      Cell: props =>
        props.original.hidden
          ? `${props.value} (${I18n.t("activerecord.attributes.user.hidden")})`
          : props.value,
      filterMethod: (filter, row) => {
        if (filter.value) {
          return `${row._original.user_name}${
            row._original.hidden ? `, ${I18n.t("activerecord.attributes.user.hidden")}` : ""
          }`.includes(filter.value);
        } else {
          return true;
        }
      },
      sortable: true,
      minWidth: 90,
    },
    {
      Header: I18n.t("activerecord.attributes.user.full_name"),
      Cell: row => `${row.original.first_name} ${row.original.last_name}`,
      minWidth: 170,
    },
    {
      Header: I18n.t("activerecord.models.group.other"),
      accessor: "groups",
      className: "number",
      filterable: false,
    },
    {
      Header: I18n.t("activerecord.models.criterion.other"),
      accessor: "criteria",
      filterable: false,
      Cell: ({value}) => {
        if (this.props.assign_graders_to_criteria) {
          return (
            <span>
              {value}/{this.props.numCriteria}
            </span>
          );
        } else {
          return I18n.t("all");
        }
      },
    },
  ];

  static getDerivedStateFromProps(props, state) {
    let filtered = [];
    for (let i = 0; i < state.filtered.length; i++) {
      if (state.filtered[i].id !== "hidden") {
        filtered.push(state.filtered[i]);
      }
    }
    if (!props.showHidden) {
      filtered.push({id: "hidden", value: false});
    }
    return {filtered};
  }

  onFilteredChange = filtered => {
    this.setState({filtered});
  };

  render() {
    return (
      <CheckboxTable
        ref={r => (this.checkboxTable = r)}
        data={this.props.graders}
        columns={this.getColumns()}
        defaultSorted={[
          {
            id: "user_name",
          },
        ]}
        loading={this.props.loading}
        filterable
        filtered={this.state.filtered}
        onFilteredChange={this.onFilteredChange}
        {...this.props.getCheckboxProps()}
      />
    );
  }
}

class RawGroupsTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      filtered: [],
    };
  }

  getColumns = () => {
    return [
      {
        accessor: "inactive",
        id: "inactive",
        width: 0,
        className: "rt-hidden",
        headerClassName: "rt-hidden",
        resizable: false,
      },
      {
        show: false,
        accessor: "_id",
        id: "_id",
      },
      {
        Header: I18n.t("activerecord.models.section", {count: 1}),
        accessor: "section",
        id: "section",
        show: this.props.showSections || false,
        minWidth: 70,
        Cell: ({value}) => {
          return this.props.sections[value] || "";
        },
        filterMethod: (filter, row) => {
          if (filter.value === "all") {
            return true;
          } else {
            return this.props.sections[row[filter.id]] === filter.value;
          }
        },
        Filter: selectFilter,
        filterOptions: Object.entries(this.props.sections).map(kv => ({
          value: kv[1],
          text: kv[1],
        })),
      },
      {
        Header: I18n.t("activerecord.models.group.one"),
        accessor: "group_name",
        id: "group_name",
        minWidth: 150,
      },
      {
        Header: I18n.t("activerecord.models.ta.other"),
        accessor: "graders",
        Cell: row => {
          return row.value.map(ta_data => (
            <div key={`${row.original._id}-${ta_data.grader}`}>
              {ta_data.hidden
                ? `${ta_data.grader} (${I18n.t("activerecord.attributes.user.hidden")})`
                : ta_data.grader}
              <a
                href="#"
                onClick={() =>
                  this.props.unassignSingle(row.original._id, ta_data.grader, "groups_table")
                }
                title={I18n.t("graders.actions.unassign_grader")}
              >
                <FontAwesomeIcon icon="fa-solid fa-trash" className="icon-right" />
              </a>
            </div>
          ));
        },
        filterable: false,
        minWidth: 100,
      },
      {
        Header: I18n.t("graders.coverage"),
        accessor: "criteria_coverage_count",
        Cell: ({value}) => (
          <span>
            {value || 0}/{this.props.numCriteria}
          </span>
        ),
        minWidth: 70,
        className: "number",
        filterable: false,
        show: this.props.showCoverage,
      },
    ];
  };

  static getDerivedStateFromProps(props, state) {
    let filtered = state.filtered.filter(group => group.id !== "inactive");

    if (!props.showInactive) {
      filtered.push({id: "inactive", value: false});
    }
    return {filtered};
  }

  onFilteredChange = filtered => {
    this.setState({filtered});
  };

  render() {
    return (
      <CheckboxTable
        ref={r => (this.checkboxTable = r)}
        data={this.props.groups}
        columns={this.getColumns()}
        defaultSorted={[
          {
            id: "group_name",
          },
        ]}
        loading={this.props.loading}
        filterable
        filtered={this.state.filtered}
        onFilteredChange={this.onFilteredChange}
        {...this.props.getCheckboxProps()}
      />
    );
  }
}

class RawCriteriaTable extends React.Component {
  getColumns = () => {
    return [
      {
        show: false,
        accessor: "_id",
        id: "_id",
      },
      {
        Header: I18n.t("activerecord.attributes.criterion.name"),
        accessor: "name",
        minWidth: 150,
      },
      {
        Header: I18n.t("activerecord.models.ta.other"),
        accessor: "graders",
        Cell: row => {
          return row.value.map(ta_data => (
            <div key={`${row.original._id}-${ta_data.grader}`}>
              {ta_data.hidden
                ? `${ta_data.grader} (${I18n.t("activerecord.attributes.user.hidden")})`
                : ta_data.grader}
              <a
                href="#"
                onClick={() =>
                  this.props.unassignSingle(row.original._id, ta_data.grader, "criteria_table")
                }
                title={I18n.t("graders.actions.unassign_grader")}
              >
                <FontAwesomeIcon icon="fa-solid fa-trash" className="icon-right" />
              </a>
            </div>
          ));
        },
        filterable: false,
        minWidth: 70,
      },
      {
        Header: I18n.t("graders.coverage"),
        accessor: "coverage",
        Cell: ({value}) => (
          <span>
            {value}/{this.props.numGroups}
          </span>
        ),
        minWidth: 70,
        className: "number",
        filterable: false,
      },
    ];
  };

  render() {
    if (this.props.display) {
      return (
        <CheckboxTable
          ref={r => (this.checkboxTable = r)}
          data={this.props.criteria}
          columns={this.getColumns()}
          defaultSorted={[
            {
              id: "_id",
            },
          ]}
          loading={this.props.loading}
          filterable
          {...this.props.getCheckboxProps()}
        />
      );
    } else {
      return null;
    }
  }
}

const GradersTable = withSelection(RawGradersTable);
const GroupsTable = withSelection(RawGroupsTable);
const CriteriaTable = withSelection(RawCriteriaTable);

class GradersActionBox extends React.Component {
  render = () => {
    let showHiddenGraderTooltip = "";
    let showHiddenGroupsTooltip = "";
    if (this.props.hiddenGradersCount !== null && this.props.hiddenGroupsCount !== null) {
      showHiddenGraderTooltip = `${I18n.t("graders.inactive_graders_count", {
        count: this.props.hiddenGradersCount,
      })}`;
      showHiddenGroupsTooltip = `${I18n.t("activerecord.attributes.grouping.inactive_groups", {
        count: this.props.hiddenGroupsCount,
      })}`;
    }

    return (
      <div className="rt-action-box">
        <span className={"flex-row-expand"}>
          <input
            id="show_hidden"
            name="show_hidden"
            type="checkbox"
            checked={this.props.showHidden}
            onChange={this.props.updateShowHidden}
            className={"hide-user-checkbox"}
          />
          <label title={showHiddenGraderTooltip} htmlFor="show_hidden">
            {I18n.t("tas.display_inactive")}
          </label>
        </span>
        <span>
          <input
            id="show_hidden_groups"
            name="show_hidden_groups"
            type="checkbox"
            checked={this.props.showHiddenGroups}
            onChange={this.props.updateShowHiddenGroups}
            className={"hide-user-checkbox"}
            data-testid={"show_hidden_groups"}
          />
          <label
            title={showHiddenGroupsTooltip}
            htmlFor="show_hidden_groups"
            data-testid={"show_hidden_groups_tooltip"}
          >
            {I18n.t("groups.display_inactive")}
          </label>
        </span>
        <button onClick={this.props.assignAll}>
          <FontAwesomeIcon icon="fa-solid fa-user-plus" />
          {I18n.t("graders.actions.assign_grader")}
        </button>
        <button onClick={this.props.openGraderDistributionModal}>
          <FontAwesomeIcon icon="fa-solid fa-dice" />
          {I18n.t("graders.actions.randomly_assign_graders")}
        </button>
        <button onClick={this.props.openSectionDistributionModal}>
          <FontAwesomeIcon icon="fa-solid fa-list" />
          {I18n.t("graders.actions.assign_by_section")}
        </button>
        <button onClick={this.props.unassignAll}>
          <FontAwesomeIcon icon="fa-solid fa-user-minus" />
          {I18n.t("graders.actions.unassign_grader")}
        </button>
      </div>
    );
  };
}

export function makeGradersManager(elem, props) {
  render(<GradersManager {...props} />, elem);
}
export {GradersManager};
