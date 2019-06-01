import React from "react";
import { render } from 'react-dom';
import FileManager from './markus_file_manager';
import Form from 'react-jsonschema-form';
import Datepicker from './date_picker'

class AutotestManager extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      files: [],
      schema: {},
      uiSchema: {
        testers: {
          items: {
            classNames: 'tester-item'
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
      loading: true
    };
  };

  componentDidMount() {
    window.modal_addnew = new ModalMarkus('#addnew_dialog');
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

  handleCreateFiles = (files) => {
    let data = new FormData();
    files.forEach(f => data.append('new_files[]', f, f.name));
    $.post({
      url: Routes.upload_files_assignment_automated_tests_path(this.props.assignment_id),
      data: data,
      processData: false, // tell jQuery not to process the data
      contentType: false  // tell jQuery not to set contentType
    }).then(this.fetchFileDataOnly);
  };

  handleDeleteFile = (fileKey) => {
    if (!this.state.files.some(f => f.key === fileKey)) {
      return;
    }
    $.post({
      url: Routes.upload_files_assignment_automated_tests_path(this.props.assignment_id),
      data: {delete_files: [fileKey]}
    }).then(this.fetchFileDataOnly)
      .then(this.endAction);
  };

  handleFormChange = (data) => {
    this.setState({formData: data.formData});
  };

  toggleEnableTest = () => {
    this.setState({enable_test: !this.state.enable_test})
  };

  toggleEnableStudentTest = () => {
    this.setState({enable_student_tests: !this.state.enable_student_tests})
  };

  toggleNonRegeneratingTokens = () => {
    this.setState({non_regenerating_tokens: !this.state.non_regenerating_tokens})
  };

  toggleUnlimitedTokens = () => {
    this.setState({unlimited_tokens: !this.state.unlimited_tokens})
  };

  handleTokenStartDateChange = (date) => {
    this.setState({token_start_date: date})
  };

  handleTokensPerPeriodChange = (event) => {
    this.setState({tokens_per_period: event.target.value})
  };

  handleTokenPeriodChange = (event) => {
    this.setState({token_period: event.target.value})
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
    }).then(() => { window.location.reload() });
  };

  studentTestsField = () => {
    return (
      <fieldset>
        <legend><span>{I18n.t("automated_tests.student_tests")}</span></legend>
        <label>
          <input
            type='checkbox'
            checked={this.state.enable_student_tests}
            onChange={this.toggleEnableStudentTest}
            disabled={!this.state.enable_test}
          />
          {I18n.t('activerecord.attributes.assignment.enable_student_tests')}
        </label>
        <div className='student_test_options'>
          <label className='inline_label'>
            {I18n.t('automated_tests.token.tokens_form')}
            <input type='number'
                   min='0'
                   value={this.state.tokens_per_period}
                   onChange={this.handleTokensPerPeriodChange}
                   disabled={this.state.unlimited_tokens ||
                   !this.state.enable_test ||
                   !this.state.enable_student_tests}
            />
          </label>
          <label className='inline_label'>
            {I18n.t('automated_tests.tokens_available_on')}
            <Datepicker
              warn_before_now={true}
              date={this.state.token_start_date}
              onChange={this.handleTokenStartDateChange}
              disabled={!this.state.enable_test || !this.state.enable_student_tests}
            />
          </label>
          <label className='inline_label'>
            {I18n.t('automated_tests.token.tokens_regenerate')}
            <input type='number'
                   min='0'
                   step='0.01'
                   value={this.state.token_period}
                   onChange={this.handleTokenPeriodChange}
                   disabled={this.state.unlimited_tokens ||
                   this.state.non_regenerating_tokens ||
                   !this.state.enable_test ||
                   !this.state.enable_student_tests}
            />
            {I18n.t("automated_tests.token.hours")}
          </label>
          <label className='inline_label'>
            <input
              type='checkbox'
              checked={this.state.non_regenerating_tokens}
              onChange={this.toggleNonRegeneratingTokens}
              disabled={!this.state.enable_test ||
              !this.state.enable_student_tests}
            />
            {I18n.t('automated_tests.token.no_regeneration')}
          </label>
          <label className='inline_label'>
            <input
              type='checkbox'
              checked={this.state.unlimited_tokens}
              onChange={this.toggleUnlimitedTokens}
              disabled={!this.state.enable_test ||
              !this.state.enable_student_tests}
            />
            {I18n.t('automated_tests.token.unlimited')}
          </label>
        </div>
      </fieldset>
    )
  };

  render() {
    return (
      <div>
        <label>
          <input
            type='checkbox'
            checked={this.state.enable_test}
            onChange={this.toggleEnableTest}
          />
          {I18n.t('activerecord.attributes.assignment.enable_test')}
        </label>
        <fieldset>
          <legend><span>{I18n.t("automated_tests.files")}</span></legend>
          <FileManager
            files={this.state.files}
            noFilesMessage={I18n.t('submissions.no_files_available')}
            readOnly={!this.state.enable_test}
            onDeleteFile={this.handleDeleteFile}
            onCreateFile={this.handleCreateFiles}
          />
        </fieldset>
        <fieldset>
          <legend><span>{'Testers'}</span></legend>
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
        <input type='submit'
               disabled={!this.state.enable_test}
               value={I18n.t('save')}
               onClick={this.onSubmit}
        >
        </input>
      </div>
    )
  }
}


export function makeAutotestManager(elem, props) {
  return render(<AutotestManager {...props} />, elem);
}
