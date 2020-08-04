import React from "react";
import { render } from 'react-dom';
import FileManager from './markus_file_manager';
import Form from 'react-jsonschema-form';
import Datepicker from './date_picker'
import FileUploadModal from './Modals/file_upload_modal'
import AutotestSpecsUploadModal from "./Modals/autotest_specs_upload_modal";

class AutotestManager extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      files: [],
      schema: {},
      uiSchema: {
        testers: {
          items: {
            classNames: 'tester-item',
            test_data: {
              items: {
                'ui:order': ['extra_info', '*']
              }
            }
          }
        }
      },
      formData: {},
      enable_test: true,
      enable_student_tests: true,
      token_start_date: '',
      tokens_per_period: 0,
      token_period: 0,
      non_regenerating_tokens: false,
      unlimited_tokens: false,
      loading: true,
      showFileUploadModal: false,
      showSpecUploadModal: false,
      uploadTarget: undefined,
      form_changed: false
    };
  };

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(Routes.populate_autotest_manager_assignment_automated_tests_path(this.props.assignment_id))
      .then(data => data.json())
      .then(data => this.setState({...data, loading: false}))
  };

  fetchFileDataOnly = () => {
    fetch(Routes.populate_autotest_manager_assignment_automated_tests_path(this.props.assignment_id))
      .then(data => data.json())
      .then(data => this.setState({files: data.files, schema: data.schema, loading: false}))
  };

  toggleFormChanged = (value) => {
    this.setState({form_changed: value}, () => set_onbeforeunload(this.state.form_changed));
  };

  handleCreateFiles = (files, unzip) => {
    const prefix = this.state.uploadTarget || '';
    this.setState({showFileUploadModal: false, uploadTarget: undefined});
    let data = new FormData();
    Array.from(files).forEach(f => data.append('new_files[]', f, f.name));
    data.append('path', prefix);
    data.append('unzip', unzip);
    $.post({
      url: Routes.upload_files_assignment_automated_tests_path(this.props.assignment_id),
      data: data,
      processData: false, // tell jQuery not to process the data
      contentType: false  // tell jQuery not to set contentType
    }).then(this.fetchFileDataOnly)
      .then(() => this.toggleFormChanged(true))
      .then(this.endAction);
  };

  handleDeleteFile = (fileKeys) => {
    if (!this.state.files.some(f => fileKeys.includes(f.key))) {
      return;
    }
    $.post({
      url: Routes.upload_files_assignment_automated_tests_path(this.props.assignment_id),
      data: {delete_files: fileKeys}
    }).then(this.fetchFileDataOnly)
      .then(() => this.toggleFormChanged(true))
      .then(this.endAction);
  };

  handleCreateFolder = (folderKey) => {
    $.post({
      url: Routes.upload_files_assignment_automated_tests_path(this.props.assignment_id),
      data: {new_folders: [folderKey]}
    }).then(this.fetchFileDataOnly)
      .then(() => this.toggleFormChanged(true))
      .then(this.endAction);
  };

  handleDeleteFolder = (folderKeys) => {
    $.post({
      url: Routes.upload_files_assignment_automated_tests_path(this.props.assignment_id),
      data: {delete_folders: folderKeys}
    }).then(this.fetchFileDataOnly)
      .then(() => this.toggleFormChanged(true))
      .then(this.endAction);
  };

  openUploadModal = (uploadTarget) => {
    this.setState({showFileUploadModal: true, uploadTarget: uploadTarget})
  };

  handleFormChange = (data) => {
    this.setState({formData: data.formData}, () => this.toggleFormChanged(true));
  };

  toggleEnableTest = () => {
    this.setState({enable_test: !this.state.enable_test}, () => this.toggleFormChanged(true));
  };

  toggleEnableStudentTest = () => {
    this.setState({enable_student_tests: !this.state.enable_student_tests}, () => this.toggleFormChanged(true));
  };

  toggleNonRegeneratingTokens = () => {
    this.setState({non_regenerating_tokens: !this.state.non_regenerating_tokens}, () => this.toggleFormChanged(true));
  };

  toggleUnlimitedTokens = () => {
    this.setState({unlimited_tokens: !this.state.unlimited_tokens}, () => this.toggleFormChanged(true));
  };

  handleTokenStartDateChange = (date) => {
    this.setState({token_start_date: date}, () => this.toggleFormChanged(true));
  };

  handleTokensPerPeriodChange = (event) => {
    this.setState({tokens_per_period: event.target.value}, () => this.toggleFormChanged(true));
  };

  handleTokenPeriodChange = (event) => {
    this.setState({token_period: event.target.value}, () => this.toggleFormChanged(true));
  };

  onSubmit = () => {
    let data = {
      assignment: {
        enable_test: this.state.enable_test,
        enable_student_tests: this.state.enable_student_tests,
        token_start_date: this.state.token_start_date,
        tokens_per_period: this.state.tokens_per_period,
        token_period: this.state.token_period,
        non_regenerating_tokens: this.state.non_regenerating_tokens,
        unlimited_tokens: this.state.unlimited_tokens
      },
      schema_form_data: this.state.formData
    };
    $.post({
      url: Routes.assignment_automated_tests_path(this.props.assignment_id),
      data: JSON.stringify(data),
      processData: false,
      contentType: 'application/json'
    }).then(() => {
      this.toggleFormChanged(false);
      window.location.reload();
    });
  };

  getDownloadAllURL = () => {
    return Routes.download_files_assignment_automated_tests_path(this.props.assignment_id);
  };

  specsDownloadURL = () => {
    return Routes.download_specs_assignment_automated_tests_path(this.props.assignment_id)
  };

  onSpecUploadModal = () => {
    this.setState({showSpecUploadModal: true})
  };

  handleUploadSpecFile = (file) => {
    this.setState({showSpecUploadModal: false});
    let data = new FormData();
    data.append('specs_file', file);
    $.post({
      url: Routes.upload_specs_assignment_automated_tests_path(this.props.assignment_id),
      data: data,
      processData: false, // tell jQuery not to process the data
      contentType: false  // tell jQuery not to set contentType
    }).then(this.fetchData())
      .then(() => this.toggleFormChanged(false))
      .then(this.endAction);
  };

  studentTestsField = () => {
    return (
      <fieldset>
        <legend><span>{I18n.t("automated_tests.student_tests")}</span></legend>
        <div className='inline-labels'>
        <label className='inline_label' htmlFor='enable_student_tests'>
          {I18n.t('activerecord.attributes.assignment.enable_student_tests')}
        </label>
        <input
          id='enable_student_tests'
          type='checkbox'
          checked={this.state.enable_student_tests}
          onChange={this.toggleEnableStudentTest}
          disabled={!this.state.enable_test}
        />
        <label className='inline_label' htmlFor='tokens_per_period'>
          {I18n.t('activerecord.attributes.assignment.tokens_per_period')}
        </label>
        <span>
          <input id='tokens_per_period'
                 type='number'
                 min='0'
                 value={this.state.tokens_per_period}
                 onChange={this.handleTokensPerPeriodChange}
                 disabled={this.state.unlimited_tokens ||
                           !this.state.enable_test ||
                           !this.state.enable_student_tests}
                 style={{marginRight: '1em'}}
          />
            <span>
              (
              <label className='inline_label' style={{minWidth: 0}} htmlFor='unlimited_tokens'>
                {I18n.t('activerecord.attributes.assignment.unlimited_tokens')}
                <input
                  id='unlimited_tokens'
                  type='checkbox'
                  checked={this.state.unlimited_tokens}
                  onChange={this.toggleUnlimitedTokens}
                  disabled={!this.state.enable_test ||
                            !this.state.enable_student_tests}
                  style={{marginLeft: '0.5em'}}
                />
              </label>
              )
            </span>
        </span>

        <label className='inline_label' htmlFor='token_start_date'>
          {I18n.t('activerecord.attributes.assignment.token_start_date')}
        </label>
        <Datepicker
          id='token_start_date'
          warn_before_now={true}
          date={this.state.token_start_date}
          onChange={this.handleTokenStartDateChange}
          disabled={!this.state.enable_test || !this.state.enable_student_tests}
        />
        <label className='inline_label' htmlFor='token_period'>
          {I18n.t('activerecord.attributes.assignment.token_period')}
        </label>
        <span>
          <input id='token_period'
                 type='number'
                 min='0'
                 step='0.01'
                 value={this.state.token_period}
                 onChange={this.handleTokenPeriodChange}
                 disabled={this.state.unlimited_tokens ||
                           this.state.non_regenerating_tokens ||
                           !this.state.enable_test ||
                           !this.state.enable_student_tests}
                 style={{marginRight: '1em'}}
          />
          {I18n.t('durations.any_hours')}
          <span style={{marginLeft: '1em'}}>
            <label className='inline_label'>
              ({I18n.t('activerecord.attributes.assignment.non_regenerating_tokens')}
              <input
                id='non_regenerating_tokens'
                type='checkbox'
                checked={this.state.non_regenerating_tokens}
                onChange={this.toggleNonRegeneratingTokens}
                disabled={!this.state.enable_test ||
                !this.state.enable_student_tests}
                style={{marginLeft: '0.5em'}}
              />
              )
            </label>
          </span>
        </span>
        </div>
    </fieldset>
    )
  };

  render() {
    return (
      <div>
        <div className='inline-labels'>
          <input
            type='checkbox'
            checked={this.state.enable_test}
            onChange={this.toggleEnableTest}
          />
          <label>
            {I18n.t('activerecord.attributes.assignment.enable_test')}
          </label>
        </div>
        <fieldset>
          <legend><span>{I18n.t("automated_tests.files")}</span></legend>
          <FileManager
            files={this.state.files}
            noFilesMessage={I18n.t('submissions.no_files_available')}
            readOnly={!this.state.enable_test}
            onDeleteFile={this.handleDeleteFile}
            onCreateFolder={this.handleCreateFolder}
            onRenameFolder={typeof this.handleCreateFolder === 'function' ? () => {} : undefined}
            onDeleteFolder={this.handleDeleteFolder}
            onActionBarAddFileClick={this.openUploadModal}
            downloadAllURL={this.getDownloadAllURL()}
            disableActions={{rename: true}}
          />
        </fieldset>
        <fieldset>
          <legend><span>{'Testers'}</span></legend>
          <div className={'rt-action-box upload-download'}>
            <a href={this.specsDownloadURL()} className={'button download-button'}>{I18n.t('download')}</a>
            <a onClick={this.onSpecUploadModal} className={'button upload-button'}>{I18n.t('upload')}</a>
          </div>
          <Form
            disabled={!this.state.enable_test}
            schema={this.state.schema}
            uiSchema={this.state.uiSchema}
            formData={this.state.formData}
            onChange={this.handleFormChange}
            noValidate={true}
          >
            <p/> {/*need something here so that the form doesn't render its own submit button*/}
          </Form>
        </fieldset>
        {this.studentTestsField()}
        <p>
          <input type='submit'
                 value={I18n.t('save')}
                 onClick={this.onSubmit}
                 disabled={!this.state.form_changed}
          >
          </input>
        </p>
        <FileUploadModal
          isOpen={this.state.showFileUploadModal}
          onRequestClose={() => this.setState({showFileUploadModal: false, uploadTarget: undefined})}
          onSubmit={this.handleCreateFiles}
        />
        <AutotestSpecsUploadModal
          isOpen={this.state.showSpecUploadModal}
          onRequestClose={() => this.setState({showSpecUploadModal: false})}
          onSubmit={this.handleUploadSpecFile}
        />
      </div>
    )
  }
}


export function makeAutotestManager(elem, props) {
  return render(<AutotestManager {...props} />, elem);
}
