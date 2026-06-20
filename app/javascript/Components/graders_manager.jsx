import React from "react";
import {createRoot} from "react-dom/client";
import {Tab, Tabs, TabList, TabPanel} from "react-tabs";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

import Table from "./table/table";
import {createColumnHelper} from "@tanstack/react-table";
import {withSelection, CheckboxTable} from "./markus_with_selection_hoc";
import {caseSensitiveIncludes} from "./Helpers/table_helpers";
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
    let groups = this.groupsTable ? this.groupsTable.getSelectedRows() : [];
    let criteria = this.criteriaTable ? this.criteriaTable.state.selection : [];
    let graders = this.gradersTable ? this.gradersTable.getSelectedRows() : [];
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
    let groups = this.groupsTable ? this.groupsTable.getSelectedRows() : [];
    let criteria = this.criteriaTable ? this.criteriaTable.state.selection : [];
    let graders = this.gradersTable ? this.gradersTable.getSelectedRows() : [];

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
    let groups = this.groupsTable ? this.groupsTable.getSelectedRows() : [];
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
    let groups = this.groupsTable ? this.groupsTable.getSelectedRows() : [];
    let criteria = this.criteriaTable ? this.criteriaTable.state.selection : [];
    let graders = this.gradersTable ? this.gradersTable.getSelectedRows() : [];

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
      return this.gradersTable.getSelectedRows().includes(grader._id);
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

const columnHelper = createColumnHelper();
class GradersTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      columnFilters: [{id: "hidden", value: false}],
      rowSelection: {},
      columns: [
        columnHelper.accessor("hidden", {
          id: "hidden",
          size: 0,
          meta: {
            className: "rt-hidden",
            headerClassName: "rt-hidden",
          },
          enableResizing: false,
        }),
        columnHelper.accessor("_id", {
          id: "_id",
        }),
        columnHelper.accessor("user_name", {
          header: I18n.t("activerecord.attributes.user.user_name"),
          id: "user_name",
          cell: ({getValue, row}) =>
            row.original.hidden
              ? `${getValue()} (${I18n.t("activerecord.attributes.user.hidden")})`
              : getValue(),
          filterFn: (row, columnId, filterValue) => {
            if (filterValue) {
              return `${row.original.user_name}${
                row.original.hidden ? `, ${I18n.t("activerecord.attributes.user.hidden")}` : ""
              }`.includes(filterValue);
            } else {
              return true;
            }
          },
          enableSorting: true,
          minSize: 90,
        }),
        columnHelper.accessor(
          row => {
            const first_name = row.first_name;
            const last_name = row.last_name;
            return `${first_name} ${last_name}`;
          },
          {
            header: I18n.t("activerecord.attributes.user.full_name"),
            id: "full_name",
            enableColumnFilter: true,
            filterFn: (row, columnId, filterValue) => {
              if (filterValue) {
                const fullName =
                  `${row.original.first_name} ${row.original.last_name}`.toLowerCase();
                return fullName.includes(filterValue.toLowerCase());
              } else {
                return true;
              }
            },
            enableSorting: true,
            minSize: 170,
          }
        ),
        columnHelper.accessor("groups", {
          header: I18n.t("activerecord.models.group.other"),
          enableColumnFilter: false,
          meta: {
            className: "number",
          },
        }),
        columnHelper.accessor("criteria", {
          header: I18n.t("activerecord.models.criterion.other"),
          enableColumnFilter: false,
          cell: ({getValue}) => {
            if (this.props.assign_graders_to_criteria) {
              return (
                <span>
                  {getValue()}/{this.props.numCriteria}
                </span>
              );
            } else {
              return I18n.t("all");
            }
          },
        }),
      ],
    };
  }

  resetSelection = () => {
    this.setState({rowSelection: {}});
  };

  getSelectedRows = () => {
    return Object.keys(this.state.rowSelection).map(id => Number(id));
  };

  componentDidUpdate(prevProps, prevState, snapshot) {
    if (prevProps.showHidden !== this.props.showHidden) {
      this.setState(prevState => {
        let newFilters = prevState.columnFilters;

        if (this.props.showHidden) {
          newFilters = newFilters.filter(f => f.id !== "hidden");
        } else {
          if (!newFilters.some(f => f.id === "hidden")) {
            newFilters = [...newFilters, {id: "hidden", value: false}];
          }
        }
        return {columnFilters: newFilters};
      });
    }
  }

  render() {
    return (
      <Table
        loading={this.props.loading}
        data={this.props.graders}
        columns={this.state.columns}
        initialState={{
          sorting: [{id: "user_name"}],
          columnVisibility: {
            hidden: false,
            _id: false,
          },
        }}
        columnFilters={this.state.columnFilters}
        onColumnFiltersChange={updaterOrValue => {
          this.setState(prevState => {
            let newFilters =
              typeof updaterOrValue === "function"
                ? updaterOrValue(prevState.columnFilters)
                : updaterOrValue;
            return {columnFilters: newFilters};
          });
        }}
        enableRowSelection={true}
        rowSelection={this.state.rowSelection}
        onRowSelectionChange={updater => {
          this.setState(prevState => ({
            rowSelection: typeof updater === "function" ? updater(prevState.rowSelection) : updater,
          }));
        }}
        getRowId={row => row._id}
      />
    );
  }
}

class GroupsTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      columnFilters: [{id: "inactive", value: false}],
      columns: this.getColumns(this.props.showCoverage, this.props.showSections),
      rowSelection: {},
      isCaseSensitive: false,
    };
  }

  componentDidUpdate(prevProps, prevState, snapshot) {
    if (
      prevProps.showSections !== this.props.showSections ||
      prevProps.sections !== this.props.sections ||
      prevProps.showCoverage !== this.props.showCoverage
    ) {
      this.setState({
        columns: this.getColumns(this.props.showCoverage, this.props.showSections),
      });
    }
    if (prevProps.showInactive !== this.props.showInactive) {
      this.setState(prevState => {
        let newFilters = prevState.columnFilters;

        if (this.props.showInactive) {
          newFilters = newFilters.filter(f => f.id !== "inactive");
        } else {
          if (!newFilters.some(f => f.id === "inactive")) {
            newFilters = [...newFilters, {id: "inactive", value: false}];
          }
        }
        return {columnFilters: newFilters};
      });
    }
  }

  getColumns = (showCoverage, showSections = false) => {
    return [
      columnHelper.accessor("inactive", {
        id: "inactive",
        size: 0,
        meta: {
          className: "rt-hidden",
          headerClassName: "rt-hidden",
        },
        enableResizing: false,
      }),
      columnHelper.accessor("_id", {
        id: "_id",
      }),
      ...(showSections
        ? [
            columnHelper.accessor(
              row => {
                const sectionId = row.section;
                return this.props.sections[sectionId] || "";
              },
              {
                header: I18n.t("activerecord.models.section", {count: 1}),
                id: "section",
                minSize: 70,
                filterFn: (row, columnId, filterValue) => {
                  if (filterValue === "all") {
                    return true;
                  } else {
                    return this.props.sections[row.original.section] === filterValue;
                  }
                },
                meta: {
                  filterVariant: "select",
                },
              }
            ),
          ]
        : []),
      columnHelper.accessor("group_name", {
        header: I18n.t("activerecord.models.group.one"),
        id: "group_name",
        minSize: 150,
        meta: {
          filterVariant: "case-sensitive-text",
          toggleCaseSensitivity: isSensitive => {
            this.setState({isCaseSensitive: isSensitive});
          },
        },
        filterFn: (row, columnId, filterValue) => {
          if (!filterValue) {
            return true;
          }
          return caseSensitiveIncludes(
            row.original[columnId],
            filterValue,
            this.state.isCaseSensitive
          );
        },
        enableColumnFilter: true,
      }),
      columnHelper.accessor("graders", {
        header: I18n.t("activerecord.models.ta.other"),
        cell: ({getValue, row}) => {
          return getValue().map(ta_data => (
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
        enableColumnFilter: false,
        minSize: 100,
      }),
      ...(showCoverage
        ? [
            columnHelper.accessor("criteria_coverage_count", {
              header: I18n.t("graders.coverage"),
              cell: ({getValue}) => {
                return (
                  <span>
                    {getValue() || 0}/{this.props.numCriteria}
                  </span>
                );
              },
              minSize: 70,
              enableColumnFilter: false,
              meta: {
                className: "number",
              },
            }),
          ]
        : []),
    ];
  };

  resetSelection = () => {
    this.setState({rowSelection: {}});
  };

  getSelectedRows = () => {
    return Object.keys(this.state.rowSelection).map(id => Number(id));
  };

  render() {
    return (
      <Table
        loading={this.props.loading}
        data={this.props.groups}
        columns={this.state.columns}
        initialState={{
          sorting: [{id: "group_name"}],
          columnVisibility: {
            _id: false,
          },
        }}
        columnFilters={this.state.columnFilters}
        onColumnFiltersChange={updaterOrValue => {
          this.setState(prevState => {
            let newFilters =
              typeof updaterOrValue === "function"
                ? updaterOrValue(prevState.columnFilters)
                : updaterOrValue;
            return {columnFilters: newFilters};
          });
        }}
        enableRowSelection={true}
        rowSelection={this.state.rowSelection}
        onRowSelectionChange={updater => {
          this.setState(prevState => ({
            rowSelection: typeof updater === "function" ? updater(prevState.rowSelection) : updater,
          }));
        }}
        getRowId={row => row._id}
      />
    );
  }
}

class RawCriteriaTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      columns: [
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
      ],
    };
  }

  render() {
    if (this.props.display) {
      return (
        <CheckboxTable
          ref={r => (this.checkboxTable = r)}
          data={this.props.criteria}
          columns={this.state.columns}
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
  const root = createRoot(elem);
  root.render(<GradersManager {...props} />);
}
export {GradersManager};
