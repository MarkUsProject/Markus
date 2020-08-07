import React from 'react';
import {render} from 'react-dom';
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';

import {withSelection, CheckboxTable} from './markus_with_selection_hoc';


class GradersManager extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      graders: [],
      groups: [],
      criteria: [],
      assign_graders_to_criteria: false,
      loading: true,
      tableName: 'groups_table', // The first tab
      skip_empty_submissions: true,
      anonymize_groups: false,
      hide_unassigned_criteria: false,
      sections: {}
    }
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    $.get({
      url: Routes.assignment_graders_path(this.props.assignment_id),
      dataType: 'json',
    }).then(res => {
      if (this.gradersTable) this.gradersTable.resetSelection();
      if (this.groupsTable) this.groupsTable.resetSelection();
      if (this.criteriaTable) this.criteriaTable.resetSelection();

      this.setState({
        graders: res.graders,
        groups: res.groups,
        criteria: res.criteria,
        assign_graders_to_criteria: res.assign_graders_to_criteria,
        loading: false,
        sections: res.sections,
        anonymize_groups: res.anonymize_groups,
        hide_unassigned_criteria: res.hide_unassigned_criteria
      });
    });
  };

  assignAll = () => {
    let groups = this.groupsTable ? this.groupsTable.state.selection : [];
    let criteria = this.criteriaTable ? this.criteriaTable.state.selection : [];
    let graders = this.gradersTable.state.selection;

    if (groups.length === 0 && criteria.length === 0) {
      alert(I18n.t('groups.select_a_group'));
      return;
    }

    if (graders.length === 0) {
      alert(I18n.t('graders.select_a_grader'));
      return;
    }

    $.post({
      url: Routes.global_actions_assignment_graders_path(this.props.assignment_id),
      data: {
        global_actions: 'assign',
        current_table: this.state.tableName,
        skip_empty_submissions: this.state.skip_empty_submissions,
        groupings: groups,
        criteria: criteria,
        graders: graders
      }
    }).then(this.fetchData);
  };

  assignRandomly = () => {
    let groups = this.groupsTable ? this.groupsTable.state.selection : [];
    let criteria = this.criteriaTable ? this.criteriaTable.state.selection : [];
    let graders = this.gradersTable.state.selection;

    if (groups.length === 0 && criteria.length === 0) {
      alert(I18n.t('groups.select_a_group'));
      return;
    }

    if (graders.length === 0) {
      alert(I18n.t('graders.select_a_grader'));
      return;
    }

    $.post({
      url: Routes.global_actions_assignment_graders_path(this.props.assignment_id),
      data: {
        global_actions: 'random_assign',
        current_table: this.state.tableName,
        skip_empty_submissions: this.state.skip_empty_submissions,
        groupings: groups,
        criteria: criteria,
        graders: graders
      }
     }).then(this.fetchData);
  };

  unassignAll = () => {
    let groups = this.groupsTable ? this.groupsTable.state.selection : [];
    let criteria = this.criteriaTable ? this.criteriaTable.state.selection : [];
    let graders = this.gradersTable.state.selection;

    if (groups.length === 0 && criteria.length === 0) {
      alert(I18n.t('groups.select_a_group'));
      return;
    }

    if (graders.length === 0) {
      alert(I18n.t('graders.select_a_grader'));
      return;
    }

    $.post({
      url: Routes.global_actions_assignment_graders_path(this.props.assignment_id),
      data: {
        global_actions: 'unassign',
        current_table: this.state.tableName,
        groupings: groups,
        criteria: criteria,
        graders: graders
      }
    }).then(this.fetchData);
  };

  unassignSingle = (id, grader_user_name, origin) => {
    let groups, criteria;
    if (origin === 'groups_table') {
      groups = [id];
      criteria = [];
    } else {
      groups = [];
      criteria = [id];
    }

    $.post({
      url: Routes.global_actions_assignment_graders_path(this.props.assignment_id),
      data: {
        global_actions: 'unassign',
        current_table: origin,
        groupings: groups,
        criteria: criteria,
        grader_user_names: [grader_user_name]
      }
    }).then(this.fetchData);
  };

  toggleSkipEmptySubmissions = () => {
    this.setState({skip_empty_submissions: !this.state.skip_empty_submissions});
  };

  toggleAssignGradersToCriteria = () => {
    const assign = !this.state.assign_graders_to_criteria;
    $.post({
      url: Routes.set_boolean_graders_options_assignment_path(this.props.assignment_id),
      data: {
        attribute: {assignment_properties_attributes: {assign_graders_to_criteria: assign}}
      },
    }).then(() => this.setState({assign_graders_to_criteria: assign}));
  };

  toggleAnonymizeGroups = () => {
    const assign = !this.state.anonymize_groups;
    $.post({
      url: Routes.set_boolean_graders_options_assignment_path(this.props.assignment_id),
      data: {
        attribute: {assignment_properties_attributes: {anonymize_groups: assign}}
      },
    }).then(() => this.setState({anonymize_groups: assign}));
  };

  toggleHideUnassignedCriteria = () => {
    const assign = !this.state.hide_unassigned_criteria;
    $.post({
      url: Routes.set_boolean_graders_options_assignment_path(this.props.assignment_id),
      data: {
        attribute: {assignment_properties_attributes: {hide_unassigned_criteria: assign}}
      },
    }).then(() => this.setState({hide_unassigned_criteria: assign}));
  };

  renderHideUnassignedCriteria = () => {
    if (this.state.assign_graders_to_criteria) {
      return <div style={{marginBottom: '1em'}}>
        <label>
          <input type="checkbox"
                 checked={this.state.hide_unassigned_criteria}
                 onChange={this.toggleHideUnassignedCriteria}
                 style={{marginRight: '5px'}}
          />
          {I18n.t('graders.hide_unassigned_criteria')}
        </label>
      </div>;
    }
  };

  onSelectTable = (index) => {
    if (index === 0) {
      this.setState({tableName: 'groups_table'});
    } else {
      this.setState({tableName: 'criteria_table'});
    }
  };

  render() {
    return (
      <div>
        <GradersActionBox
          assignAll={this.assignAll}
          assignRandomly={this.assignRandomly}
          unassignAll={this.unassignAll}
        />
        <div className='mapping-tables'>
          <div className='mapping-table'>
            <GradersTable
              ref={(r) => this.gradersTable = r}
              graders={this.state.graders} loading={this.state.loading}
              assign_graders_to_criteria={this.state.assign_graders_to_criteria}
              numCriteria={this.state.criteria.length}
            />
          </div>
          <div className='mapping-table'>
            <Tabs onSelect={this.onSelectTable}>
              <TabList>
                <Tab>{I18n.t('activerecord.models.group.other')}</Tab>
                <Tab>{I18n.t('activerecord.models.criterion.other')}</Tab>
              </TabList>

              <TabPanel>
                <div style={{marginBottom: '1em'}}>
                  <label>
                    <input type="checkbox"
                           checked={this.state.skip_empty_submissions}
                           onChange={this.toggleSkipEmptySubmissions}
                           style={{marginRight: '5px'}}
                    />
                    {I18n.t('graders.skip_empty_submissions')}
                  </label>
                </div>
                <div style={{marginBottom: '1em'}}>
                  <label>
                    <input type="checkbox"
                           checked={this.state.anonymize_groups}
                           onChange={this.toggleAnonymizeGroups}
                           style={{marginRight: '5px'}}
                    />
                    {I18n.t('graders.anonymize_groups')}
                  </label>
                </div>
                <GroupsTable
                  ref={(r) => this.groupsTable = r}
                  groups={this.state.groups} loading={this.state.loading}
                  unassignSingle={this.unassignSingle}
                  showSections={this.props.showSections}
                  sections={this.state.sections}
                  numCriteria={this.state.criteria.length}
                  showCoverage={this.state.assign_graders_to_criteria}
                />
              </TabPanel>
              <TabPanel>
                <div style={{marginBottom: '1em'}}>
                  <label>
                    <input type="checkbox"
                           onChange={this.toggleAssignGradersToCriteria}
                           checked={this.state.assign_graders_to_criteria}
                           style={{marginRight: '5px'}}
                    />
                    {I18n.t('graders.assign_to_criteria')}
                  </label>
                </div>
                { this.renderHideUnassignedCriteria() }
                <CriteriaTable
                  display={this.state.assign_graders_to_criteria}
                  ref={(r) => this.criteriaTable = r}
                  criteria={this.state.criteria} loading={this.state.loading}
                  unassignSingle={this.unassignSingle}
                  numGroups={this.state.groups.length}
                />
              </TabPanel>
            </Tabs>
          </div>
        </div>
      </div>
    );
  }
}


class RawGradersTable extends React.Component {
  getColumns = () => [
    {
      show: false,
      accessor: '_id',
      id: '_id'
    },
    {
      Header: I18n.t('activerecord.attributes.user.user_name'),
      accessor: 'user_name',
      id: 'user_name'
    },
    {
      Header: I18n.t('activerecord.attributes.user.full_name'),
      Cell: row => `${row.original.first_name} ${row.original.last_name}`,
      minWidth: 170
    },
    {
      Header: I18n.t('activerecord.models.group.other'),
      accessor: 'groups',
      className: 'number',
      filterable: false
    },
    {
      Header: I18n.t('activerecord.models.criterion.other'),
      accessor: 'criteria',
      filterable: false,
      Cell: ({value}) => {
        if (this.props.assign_graders_to_criteria) {
          return <span>{value}/{this.props.numCriteria}</span>;
        } else {
          return I18n.t('all');
        }
      }
    },
  ];

  render() {
    return (
      <CheckboxTable
        ref={(r) => this.checkboxTable = r}

        data={this.props.graders}
        columns={this.getColumns()}
        defaultSorted={[
          {
            id: 'user_name'
          }
        ]}
        loading={this.props.loading}
        filterable

        {...this.props.getCheckboxProps()}
      />
    );
  }
}


class RawGroupsTable extends React.Component {
  getColumns = () => {
    return [
      {
        show: false,
        accessor: '_id',
        id: '_id'
      },
      {
        Header: I18n.t('activerecord.models.section', {count: 1}),
        accessor: 'section',
        id: 'section',
        show: this.props.showSections || false,
        minWidth: 70,
        Cell: ({ value }) => {
          return this.props.sections[value] || '';
        },
        filterMethod: (filter, row) => {
          if (filter.value === 'all') {
            return true;
          } else {
            return this.props.sections[row[filter.id]] === filter.value;
          }
        },
        Filter: ({ filter, onChange }) =>
          <select
            onChange={event => onChange(event.target.value)}
            style={{ width: '100%' }}
            value={filter ? filter.value : 'all'}
          >
            <option value='all'>{I18n.t('all')}</option>
            {Object.entries(this.props.sections).map(
              kv => <option key={kv[1]} value={kv[1]}>{kv[1]}</option>)}
          </select>,
      },
      {
        Header: I18n.t('activerecord.models.group.one'),
        accessor: 'group_name',
        id: 'group_name',
        minWidth: 150,
      },
      {
        Header: I18n.t('activerecord.models.ta.other'),
        accessor: 'graders',
        Cell: row => {
          return row.value.map((ta) =>
            <div key={`${row.original._id}-${ta}`} className='grader-row'>
              {ta}
              <a href='#'
                 className="remove-icon"
                 onClick={() => this.props.unassignSingle(row.original._id, ta, 'groups_table')}
                 title={I18n.t('graders.actions.unassign_grader')}
              />
            </div>
          )
        },
        filterable: false,
        minWidth: 100,
      },
      {
        Header: I18n.t('graders.coverage'),
        accessor: 'criteria_coverage_count',
        Cell: ({value}) => <span>{value || 0}/{this.props.numCriteria}</span>,
        minWidth: 70,
        className: 'number',
        filterable: false,
        show: this.props.showCoverage,
      },
    ];
  };

  render() {
    return (
      <CheckboxTable
        ref={(r) => this.checkboxTable = r}

        data={this.props.groups}
        columns={this.getColumns()}
        defaultSorted={[
          {
            id: 'group_name'
          }
        ]}
        loading={this.props.loading}
        filterable

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
        accessor: '_id',
        id: '_id'
      },
      {
        Header: I18n.t('activerecord.attributes.criterion.name'),
        accessor: 'name',
        minWidth: 150
      },
      {
        Header: I18n.t('activerecord.models.ta.other'),
        accessor: 'graders',
        Cell: row => {
          return row.value.map((ta) =>
            <div key={`${row.original._id}-${ta}`} className='grader-row'>
              {ta}
              <a href='#'
                 className="remove-icon"
                 onClick={() => this.props.unassignSingle(row.original._id, ta, 'criteria_table')}
                 title={I18n.t('graders.actions.unassign_grader')}
              />
            </div>
          )
        },
        filterable: false,
        minWidth: 70
      },
      {
        Header: I18n.t('graders.coverage'),
        accessor: 'coverage',
        Cell: ({value}) => <span>{value}/{this.props.numGroups}</span>,
        minWidth: 70,
        className: 'number',
        filterable: false
      }
    ];
  };

  render() {
    if (this.props.display) {
      return (
        <CheckboxTable
          ref={(r) => this.checkboxTable = r}

          data={this.props.criteria}
          columns={this.getColumns()}
          defaultSorted={[
            {
              id: '_id'
            }
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
    return (
      <div className='rt-action-box'>
        <button
          className='assign-all-button'
          onClick={this.props.assignAll}
        >
          {I18n.t('graders.actions.assign_grader')}
        </button>
        <button
          className='assign-randomly-button'
          onClick={this.props.assignRandomly}
        >
          {I18n.t('graders.actions.randomly_assign_graders')}
        </button>
        <button
          className='unassign-all-button'
          onClick={this.props.unassignAll}
        >
          {I18n.t('graders.actions.unassign_grader')}
        </button>
      </div>
    )
  };
}


export function makeGradersManager(elem, props) {
  render(<GradersManager {...props} />, elem);
}
