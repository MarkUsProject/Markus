import React from 'react';
import {render} from "react-dom";
import FileManager from "./markus_file_manager";
import FileUploadModal from "./Modals/file_upload_modal";
import ReactTable from "react-table";

class StarterCodeManager extends React.Component {

  constructor() {
    super();
    this.state = {
      loading: true,
      dirUploadTarget: undefined,
      groupUploadTarget: undefined,
      showFileUploadModal: false,
      starterCodeType: 'simple',
      defaultStarterCodeGroup: '',
      files: {},
      sections: {}
    }
  }

  componentDidMount() {
    this.fetchData();
  }

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
        name: 'New Starter Code Group' // TODO: internationalize this
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

  handleCreateFiles = (groupUploadTarget, files) => {
    const prefix = this.state.dirUploadTarget || '';
    let data = new FormData();
    Array.from(files).forEach(f => data.append('new_files[]', f, f.name));
    data.append('path', prefix);
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
    if (original_name !== new_name) {
      $.ajax({
        type: "PUT",
        url: Routes.assignment_starter_code_group_path(
          this.props.assignment_id, groupUploadTarget
        ),
        data: {name: new_name}
      }).then(this.fetchData);
    }
  };

  renderFileManagers = () => {
    return (
      <React.Fragment>
        {Object.entries(this.state.files).map( (data, index) => {
          const {id, name, files} = data[1];
          return (
            <div key={index}>
              <StarterCodeGroupName
                name={name}
                groupUploadTarget={id}
                changeGroupName={this.changeGroupName}
              />
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
                onClick={() => this.deleteStarterCodeGroup(id)}
              >
                Delete
              </button> {/* TODO: add styling to right align with x icon */}
            </div>
          );
        })}
      </React.Fragment>
    )
  };

  updateStarterCodeType = (event) => {
    const type = event.target.value;
    if (type !== this.state.starterCodeType) {
      $.ajax({
        type: "PUT",
        url: Routes.update_starter_code_rule_type_assignment_path(
          this.props.assignment_id
        ),
        data: {starter_code_type: type}
      }).then(this.fetchData);
    }
  };

  updateDefaultStarterCode = (event) => {
    const id = event.target.value;
    $.ajax({
      type: 'PUT',
      url: Routes.assignment_starter_code_group_path(
        this.props.assignment_id, id
      ),
      data: {is_default: true}
    }).then(this.fetchData)
  };

  updateSectionStarterCode = (event) => {
    let [section_id, group_id] = event.target.value.split('_');
    $.post({
      url: Routes.update_starter_code_group_section_path(
        section_id
      ),
      data: {assignment_id: this.props.assignment_id, starter_code_group_id: group_id}
    }).then(this.fetchData)
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
              onChange={this.updateStarterCodeType}
            />
            Simple
          </label>
        </div>
        <div>
          <label>
            <input
              type={'radio'}
              name={'starter_code_type'}
              value={'sections'}
              checked={this.state.starterCodeType === 'sections'}
              onChange={this.updateStarterCodeType}
            />
            Sections
          </label>
        </div>
        <div>
          <label>
            <input
              type={'radio'}
              name={'starter_code_type'}
              value={'shuffle'}
              checked={this.state.starterCodeType === 'shuffle'}
              onChange={this.updateStarterCodeType}
            />
            Shuffle
          </label>
        </div>
        <div>
          <label>
            <input
              type={'radio'}
              name={'starter_code_type'}
              value={'group'}
              checked={this.state.starterCodeType === 'group'}
              onChange={this.updateStarterCodeType}
            />
            Group
          </label>
        </div>
      </div>
    )
  };

  renderStarterCodeAssigner = () => {
    if (['simple', 'sections'].includes(this.state.starterCodeType)) {
      let default_selector = (
        <label>
          Default Starter Code Group {/* TODO: internationalize this */}
          <select onChange={this.updateDefaultStarterCode} value={this.state.defaultStarterCodeGroup}>
            <option disabled value={''}/>
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
              {Header: 'section', accessor: 'section_name'},
              {
                Header: 'starter code group',
                Cell: row => {
                  let selected;
                  if (row.original.group_id) {
                    selected = `${row.original.section_id}_${row.original.group_id}`;
                  } else {
                    selected = `${row.original.section_id}_`;
                  }
                  return (
                    <select onChange={this.updateSectionStarterCode} value={selected}>
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

  render() {
    return (
      <div>
        {this.renderFileManagers()}
        <button
          key={'create_starter_code_group_button'}
          onClick={this.createStarterCodeGroup}
        >
          New
        </button> {/* TODO: add styling to right align with + icon */}
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
        {this.renderStarterCodeTypes()}
        {this.renderStarterCodeAssigner()}
      </div>
    )
  }
}

class StarterCodeGroupName extends React.Component {
  blurOnEnter = (event) => {
    if (event.key === 'Enter') { document.activeElement.blur() }
  };

  render() {
    return (
      <input
        type={'text'}
        placeholder={this.props.name}
        onKeyPress={this.blurOnEnter}
        onBlur={(e) => this.props.changeGroupName(this.props.groupUploadTarget, this.props.name, e)}
      />
    ) // TODO: add styling to make this more like a title
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
