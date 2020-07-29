import React from 'react';
import {render} from "react-dom";
import FileManager from "./markus_file_manager";
import FileUploadModal from "./Modals/file_upload_modal";
import ReactTable from "react-table";

function blurOnEnter(event) {
  if (event.key === 'Enter') { document.activeElement.blur() }
}

class StarterCodeManager extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      loading: true,
      dirUploadTarget: undefined,
      groupUploadTarget: undefined,
      showFileUploadModal: false,
      starterCodeType: 'simple',
      defaultStarterCodeGroup: '',
      files: {},
      sections: {},
      form_changed: false,
    }
  }

  componentDidMount() {
    this.fetchData();
  }

  toggleFormChanged = (value) => {
    this.setState({form_changed: value}, () => set_onbeforeunload(this.state.form_changed));
  };

  fetchData = () => {
    $.get({
      url: Routes.populate_starter_code_manager_assignment_path(this.props.assignment_id),
      dataType: 'json'
    }).then(res => this.setState({loading: false, ...res}));
  };

  createStarterCodeGroup = () => {
    $.post({
      url: Routes.assignment_starter_code_groups_path(this.props.assignment_id),
      data: {
        assessment_id: this.props.assignment_id,
        name: I18n.t('assignments.starter_code.new_starter_code_group')
      }
    }).then(this.fetchData)
  };

  deleteStarterCodeGroup = (starter_code_group_id) => {
    $.ajax({
      url: Routes.assignment_starter_code_group_path(this.props.assignment_id, starter_code_group_id),
      method: 'DELETE'
    }).then(this.fetchData)
  };

  handleDeleteFile = (groupUploadTarget, fileKeys) => {
    $.post({
      url: Routes.update_files_assignment_starter_code_group_path(
        this.props.assignment_id, groupUploadTarget
      ),
      data: {delete_files: fileKeys}
    }).then(() => this.setState({groupUploadTarget: undefined})).then(this.fetchData);
  };

  handleCreateFiles = (groupUploadTarget, files, unzip) => {
    const prefix = this.state.dirUploadTarget || '';
    let data = new FormData();
    Array.from(files).forEach(f => data.append('new_files[]', f, f.name));
    data.append('path', prefix);
    data.append('unzip', unzip);
    $.post({
      url: Routes.update_files_assignment_starter_code_group_path(
        this.props.assignment_id, groupUploadTarget,
      ),
      data: data,
      processData: false, // tell jQuery not to process the data
      contentType: false  // tell jQuery not to set contentType
    }).then(() => this.setState({showFileUploadModal: false, dirUploadTarget: undefined, groupUploadTarget: undefined}))
      .then(this.fetchData);
  };

  handleCreateFolder = (groupUploadTarget, folderKey) => {
    $.post({
      url: Routes.update_files_assignment_starter_code_group_path(
        this.props.assignment_id, groupUploadTarget
      ),
      data: {new_folders: [folderKey]}
    }).then(this.fetchData);
  };

  handleDeleteFolder = (groupUploadTarget, folderKeys) => {
    $.post({
      url: Routes.update_files_assignment_starter_code_group_path(
        this.props.assignment_id, groupUploadTarget
      ),
      data: {delete_folders: folderKeys}
    }).then(this.fetchData);
  };

  openUploadModal = (groupUploadTarget, uploadTarget) => {
    this.setState({showFileUploadModal: true, dirUploadTarget: uploadTarget, groupUploadTarget: groupUploadTarget})
  };

  changeGroupName = (groupUploadTarget, original_name, event) => {
    const new_name = event.target.value;
    if (!!new_name && original_name !== new_name) {
      $.ajax({
        type: "PUT",
        url: Routes.assignment_starter_code_group_path(
          this.props.assignment_id, groupUploadTarget
        ),
        data: {name: new_name}
      }).then(this.fetchData);
    }
  };

  saveStateChanges = () => {
    const data = {
      assignment: {
        starter_code_type: this.state.starterCodeType,
        default_starter_code_group_id: this.state.defaultStarterCodeGroup
      },
      sections: this.state.sections,
      starter_code_groups: this.state.files.map((data) => {
        let {files, ...rest} = data;
        return rest
      }),
    };
    $.ajax({
      type: "PUT",
      url: Routes.update_starter_code_assignment_path(this.props.assignment_id),
      data: JSON.stringify(data),
      processData: false,
      contentType: 'application/json'
    }).then(this.fetchData)
      .then(() => this.toggleFormChanged(false));
  };

  changeGroupRename = (groupUploadTarget, new_name) => {
    this.setState((prevState) => {
      let new_files = prevState.files.map( (files) => {
        if (files.id === groupUploadTarget) {
          files.entry_rename = new_name
        }
        return files;
      });
      return {files: new_files};
    }, () => this.toggleFormChanged(true));
  };

  changeGroupUseRename = (groupUploadTarget, checked) => {
    this.setState((prevState) => {
      let new_files = prevState.files.map( (files) => {
        if (files.id === groupUploadTarget) {
          files.use_rename = checked
        }
        return files;
      });
      return {files: new_files};
    }, () => this.toggleFormChanged(true));
  };

  renderFileManagers = () => {
    return (
      <React.Fragment>
        {Object.entries(this.state.files).map( (data, index) => {
          const {id, name, files} = data[1];
          return (
            <fieldset key={index}>
              <legend>
                <StarterCodeGroupName
                  name={name}
                  groupUploadTarget={id}
                  index={index}
                  changeGroupName={this.changeGroupName}
                />
              </legend>
              <StarterCodeFileManager
                groupUploadTarget={id}
                files={files}
                noFilesMessage={I18n.t('submissions.no_files_available')}
                readOnly={false}
                onDeleteFile={this.handleDeleteFile}
                onCreateFolder={this.handleCreateFolder}
                onRenameFolder={typeof this.handleCreateFolder === 'function' ? () => {} : undefined}
                onDeleteFolder={this.handleDeleteFolder}
                onActionBarAddFileClick={this.openUploadModal}
                downloadAllURL={Routes.download_files_assignment_starter_code_group_path(this.props.assignment_id, id)}
                disableActions={{rename: true}}
                canFilter={false}
              />
              <button
                key={'delete_starter_code_group_button'}
                className={'button remove-icon'}
                onClick={() => this.deleteStarterCodeGroup(id)}
              />
            </fieldset>
          );
        })}
      </React.Fragment>
    )
  };

  updateSectionStarterCode = (event) => {
    let [section_id, group_id] = event.target.value.split('_').map( (val) => { return parseInt(val) || null } );
    this.setState((prevState) => {
      let new_sections = prevState.sections.map( (section) => {
        if (section.section_id === section_id) {
          section.group_id = group_id
        }
        return section;
      });
      return {sections: new_sections};
    }, () => this.toggleFormChanged(true));
  };

  renderStarterCodeTypes = () => {
    return (
      <div>
        <div>
          <label>
            <input
              type={'radio'}
              name={'starter_code_type'}
              value={'simple'}
              checked={this.state.starterCodeType === 'simple'}
              disabled={!this.state.files.length}
              onChange={() => { this.setState({starterCodeType: 'simple'}, () => this.toggleFormChanged(true)) }}
            />
            {I18n.t('assignments.starter_code.starter_code_rule_types.simple')}
          </label>
        </div>
        <div>
          <label>
            <input
              type={'radio'}
              name={'starter_code_type'}
              value={'sections'}
              checked={this.state.starterCodeType === 'sections'}
              disabled={!this.state.files.length}
              onChange={() => { this.setState({starterCodeType: 'sections'}, () => this.toggleFormChanged(true)) }}
            />
            {I18n.t('assignments.starter_code.starter_code_rule_types.sections')}
          </label>
        </div>
        <div>
          <label>
            <input
              type={'radio'}
              name={'starter_code_type'}
              value={'shuffle'}
              checked={this.state.starterCodeType === 'shuffle'}
              disabled={!this.state.files.length}
              onChange={() => { this.setState({starterCodeType: 'shuffle'}, () => this.toggleFormChanged(true)) }}
            />
            {I18n.t('assignments.starter_code.starter_code_rule_types.shuffle')}
          </label>
        </div>
        <div>
          <label>
            <input
              type={'radio'}
              name={'starter_code_type'}
              value={'group'}
              checked={this.state.starterCodeType === 'group'}
              disabled={!this.state.files.length}
              onChange={() => { this.setState({starterCodeType: 'group'}, () => this.toggleFormChanged(true)) }}
            />
            {I18n.t('assignments.starter_code.starter_code_rule_types.group')}
          </label>
        </div>
      </div>
    )
  };

  renderStarterCodeAssigner = () => {
    if (['simple', 'sections'].includes(this.state.starterCodeType)) {
      let default_selector = (
        <label>
          {I18n.t('assignments.starter_code.default_starter_code_group')}
          <select
            onChange={(e) => this.setState(
              {defaultStarterCodeGroup: parseInt(e.target.value)}, () => this.toggleFormChanged(true)
            )}
            value={this.state.defaultStarterCodeGroup}
            disabled={!this.state.files.length}
          >
            {Object.entries(this.state.files).map( (data, index) => {
              const {id, name} = data[1];
              return (
                <option value={id} key={id}>{index + 1}: {name}</option>
              );
            })}
          </select>
        </label>
      );

      let section_table = '';
      if (this.state.starterCodeType === 'sections') {
        section_table = (
          <ReactTable
            columns={[
              {Header: I18n.t('activerecord.models.section.one'), accessor: 'section_name'},
              {
                Header: I18n.t('activerecord.models.starter_code_group.one'),
                Cell: row => {
                  let selected = `${row.original.section_id}_${row.original.group_id || ''}`;
                  return (
                    <select
                      onChange={this.updateSectionStarterCode}
                      value={selected}
                      disabled={!this.state.files.length}
                    >
                      <option value={`${row.original.section_id}_`}/>
                      {Object.entries(this.state.files).map( (data, index) => {
                        const {id, name} = data[1];
                        const value = `${row.original.section_id}_${id}`;
                        return (
                          <option value={value} key={id}>{index + 1}: {name}</option>
                        );
                      })}
                    </select>
                  );
                }
              }
            ]}
            data={this.state.sections}
          />
        );
      }
      return (
        <div>
          {default_selector}
          {section_table}
        </div>
      )
    }
    return '';
  };

  renderStarterCodeRenamer = () => {
    if (this.state.starterCodeType === 'shuffle') {
      return (
        <ReactTable
          columns={[
            {Header: I18n.t('activerecord.models.starter_code_group.one'),
             Cell: row => `${row.index + 1}: ${row.original.name}`},
            {Header: I18n.t('assignments.starter_code.rename'),
             Cell: row => {
              return (
                <StarterCodeEntryRenameInput
                  entry_rename={row.original.entry_rename}
                  use_rename={row.original.use_rename}
                  groupUploadTarget={row.original.id}
                  changeGroupRename={this.changeGroupRename}
                  changeGroupUseRename={this.changeGroupUseRename}
                />
              )
             }
            }
          ]}
          data={this.state.files}
        />
      )
    }
    return '';
  };

  render() {
    return (
      <div>
        <fieldset className={'starter_code_properties'}>
          <legend>
            <span>{I18n.t('activerecord.models.starter_code_group.other')}</span>
          </legend>
          {this.renderFileManagers()}
          <button
            key={'create_starter_code_group_button'}
            className={'button add-new-button'}
            onClick={this.createStarterCodeGroup}
          />
          <StarterCodeFileUploadModal
            groupUploadTarget={this.state.groupUploadTarget}
            isOpen={this.state.showFileUploadModal}
            onRequestClose={() => this.setState({
              showFileUploadModal: false,
              groupUploadTarget: undefined,
              dirUploadTarget: undefined
            })}
            onSubmit={this.handleCreateFiles}
          />
        </fieldset>
        <fieldset className={'starter-code-rule-types'}>
          <legend>
            <span>{I18n.t('assignments.starter_code.starter_code_rule')}</span>
          </legend>
          <div className={'download-button'}>
            <a href={Routes.download_starter_code_mappings_assignment_path(this.props.assignment_id)}>
              {I18n.t('assignments.starter_code.download_mappings_csv')}
            </a>
          </div>
          {this.renderStarterCodeTypes()}
          {this.renderStarterCodeAssigner()}
          {this.renderStarterCodeRenamer()}
          <button
            onClick={this.saveStateChanges}
            disabled={!this.state.form_changed}
          >
            {I18n.t('save')}
          </button>
        </fieldset>
      </div>
    )
  }
}

class StarterCodeGroupName extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      editing: false
    }
  }

  handleBlur = (event) => {
    this.setState(
      {editing: false},
      this.props.changeGroupName(this.props.groupUploadTarget, this.props.name, event)
    );
  };

  render() {
    if (this.state.editing) {
      return (
        <input
          autoFocus
          type={'text'}
          placeholder={this.props.name}
          onKeyPress={blurOnEnter}
          onBlur={this.handleBlur}
        />
      )
    } else {
      return (
        <h3>
          {`${this.props.index + 1}: `}
          <a href={'#'} onClick={() => {this.setState({editing: true})}}>
            {this.props.name}
          </a>
        </h3>
      )
    }
  }
}

class StarterCodeEntryRenameInput extends React.Component {
  handleBlur = (event) => {
    this.props.changeGroupRename(this.props.groupUploadTarget, event.target.value);
  };

  handleClick = (event) => {
    this.props.changeGroupUseRename(this.props.groupUploadTarget, !event.target.checked)
  };

  render() {
    return (
      <span className={'starter-code-rename-cell-content'}>
        <input
          className={'rename-input'}
          type={'text'}
          placeholder={this.props.entry_rename}
          onKeyPress={blurOnEnter}
          onBlur={this.handleBlur}
          disabled={!this.props.use_rename || this.props.disabled}
        />
        <label className={'original-checkbox'}>
          <input
            type={'checkbox'}
            onChange={this.handleClick}
            checked={!this.props.use_rename || this.props.disabled}
          />
          {I18n.t('assignments.starter_code.use_original_filename')}
        </label>
      </span>
    )
  }
}

class StarterCodeFileUploadModal extends React.Component {

  onSubmit = (...args) => {
    return this.props.onSubmit(this.props.groupUploadTarget, ...args);
  };

  render() {
    return <FileUploadModal {...this.props} onSubmit={this.onSubmit}/>;
  }
}

class StarterCodeFileManager extends React.Component {

  overridenProps = () => {
    return {
      onDeleteFile: (...args) => this.props.onDeleteFile(this.props.groupUploadTarget, ...args),
      onCreateFolder: (...args) => this.props.onCreateFolder(this.props.groupUploadTarget, ...args),
      onDeleteFolder: (...args) => this.props.onDeleteFolder(this.props.groupUploadTarget, ...args),
      onActionBarAddFileClick: (...args) => this.props.onActionBarAddFileClick(this.props.groupUploadTarget, ...args)
    }
  };

  render() {
    return <FileManager { ...{...this.props, ...this.overridenProps()} }/>;
  }
}

export function makeStarterCodeManager(elem, props) {
  render(<StarterCodeManager {...props} />, elem);
}
