import React from "react";
import {createRoot} from "react-dom/client";
import FileManager from "./markus_file_manager";
import Form from "@rjsf/core";
import {TranslatableString} from "@rjsf/utils";
import {customizeValidator} from "@rjsf/validator-ajv8";
import Flatpickr from "react-flatpickr";
import labelPlugin from "flatpickr/dist/plugins/labelPlugin/labelPlugin";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import FileUploadModal from "./Modals/file_upload_modal";
import AutotestSpecsUploadModal from "./Modals/autotest_specs_upload_modal";
import {flashMessage} from "../common/flash";

const ajvOptionsOverrides = {discriminator: true};
const validator = customizeValidator({ajvOptionsOverrides});

class AutotestManager extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      files: [],
      schema: {},
      uiSchema: {
        testers: {
          items: {
            "ui:classNames": "tester-item",
            "ui:placeholder": I18n.t("automated_tests.tester", {count: 1}),
            "ui:title": I18n.t("automated_tests.tester", {count: 1}),
            env_data: {
              pip_requirements: {
                "ui:widget": "textarea",
              },
              pip_requirements_file: {
                "ui:title": (
                  <div
                    className="pip_requirements_file_title"
                    title={I18n.t("automated_tests.requirements_file_tooltip")}
                  >
                    {I18n.t("automated_tests.requirements_file")}
                  </div>
                ),
              },
            },
            test_data: {
              items: {
                "ui:placeholder": I18n.t("automated_tests.test_group", {count: 1}),
                "ui:title": I18n.t("automated_tests.test_group", {count: 1}),
                "ui:order": ["extra_info", "*", "feedback_file_names"],
                "ui:options": {label: false},
                category: {
                  "ui:title": I18n.t("automated_tests.category"),
                },
                feedback_file_names: {
                  "ui:classNames": "feedback-file-names",
                  "ui:options": {orderable: false},
                  items: {
                    "ui:placeholder": I18n.t("attributes.filename"),
                    "ui:options": {label: false},
                    "ui:title": I18n.t("attributes.filename"),
                  },
                },
                script_files: {
                  items: {
                    "ui:options": {label: false},
                  },
                },
                student_files: {
                  items: {
                    "ui:options": {label: false},
                  },
                },
                timeout: {
                  "ui:title": I18n.t("automated_tests.timeout"),
                  "ui:widget": "updown",
                },
              },
            },
            "ui:options": {label: false},
            "ui:order": ["tester_type", "env_data", "test_data", "*"],
          },
        },
      },
      formData: {},
      enable_test: true,
      enable_student_tests: true,
      token_start_date: "",
      token_end_date: "",
      tokens_per_period: 0,
      token_period: 0,
      non_regenerating_tokens: false,
      unlimited_tokens: false,
      loading: true,
      submitted: false,
      showFileUploadModal: false,
      showSpecUploadModal: false,
      uploadTarget: undefined,
      form_changed: false,
    };
    this.formRef = React.createRef();
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(
      Routes.populate_autotest_manager_course_assignment_automated_tests_path(
        this.props.course_id,
        this.props.assignment_id
      )
    )
      .then(data => data.json())
      .then(data => this.setState({...data, loading: false, submitted: false}));
  };

  fetchFileDataOnly = () => {
    fetch(
      Routes.populate_autotest_manager_course_assignment_automated_tests_path(
        this.props.course_id,
        this.props.assignment_id
      )
    )
      .then(data => data.json())
      .then(data =>
        this.setState({
          files: data.files,
          schema: data.schema,
          loading: false,
        })
      );
  };

  toggleFormChanged = value => {
    this.setState({form_changed: value});
  };

  handleCreateFiles = (files, path, unzip) => {
    const prefix = path || this.state.uploadTarget || "";
    this.setState({showFileUploadModal: false, uploadTarget: undefined});
    let data = new FormData();
    Array.from(files).forEach(f => data.append("new_files[]", f, f.name));
    data.append("path", prefix);
    data.append("unzip", unzip);
    $.post({
      url: Routes.upload_files_course_assignment_automated_tests_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: data,
      processData: false, // tell jQuery not to process the data
      contentType: false, // tell jQuery not to set contentType
    })
      .then(this.fetchFileDataOnly)
      .then(() => this.toggleFormChanged(true))
      .then(this.endAction)
      .fail(jqXHR => {
        if (jqXHR.getResponseHeader("x-message-error") == null) {
          flashMessage(I18n.t("upload_errors.generic"), "error");
        }
      });
  };

  handleDeleteFile = fileKeys => {
    if (!this.state.files.some(f => fileKeys.includes(f.key))) {
      return;
    }
    $.post({
      url: Routes.upload_files_course_assignment_automated_tests_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {delete_files: fileKeys},
    })
      .then(this.fetchFileDataOnly)
      .then(() => this.toggleFormChanged(true))
      .then(this.endAction);
  };

  handleCreateFolder = folderKey => {
    $.post({
      url: Routes.upload_files_course_assignment_automated_tests_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {new_folders: [folderKey], path: this.state.uploadTarget || ""},
    })
      .then(this.fetchFileDataOnly)
      .then(() => this.toggleFormChanged(true))
      .then(this.endAction);
  };

  handleDeleteFolder = folderKeys => {
    $.post({
      url: Routes.upload_files_course_assignment_automated_tests_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {delete_folders: folderKeys},
    })
      .then(this.fetchFileDataOnly)
      .then(() => this.toggleFormChanged(true))
      .then(this.endAction);
  };

  openUploadModal = uploadTarget => {
    this.setState({showFileUploadModal: true, uploadTarget: uploadTarget});
  };

  handleFormChange = data => {
    this.setState({formData: data.formData}, () => this.toggleFormChanged(true));
  };

  toggleEnableTest = () => {
    this.setState({enable_test: !this.state.enable_test}, () => this.toggleFormChanged(true));
  };

  toggleEnableStudentTest = () => {
    this.setState({enable_student_tests: !this.state.enable_student_tests}, () =>
      this.toggleFormChanged(true)
    );
  };

  toggleNonRegeneratingTokens = () => {
    this.setState({non_regenerating_tokens: !this.state.non_regenerating_tokens}, () =>
      this.toggleFormChanged(true)
    );
  };

  toggleUnlimitedTokens = () => {
    this.setState({unlimited_tokens: !this.state.unlimited_tokens}, () =>
      this.toggleFormChanged(true)
    );
  };

  handleTokenStartDateChange = selectedDates => {
    const newDate = selectedDates[0] || "";
    this.setState({token_start_date: newDate}, () => this.toggleFormChanged(true));
  };

  handleTokenEndDateChange = selectedDates => {
    const newDate = selectedDates[0] || "";
    this.setState({token_end_date: newDate}, () => this.toggleFormChanged(true));
  };

  handleTokensPerPeriodChange = event => {
    this.setState({tokens_per_period: event.target.value}, () => this.toggleFormChanged(true));
  };

  handleTokenPeriodChange = event => {
    this.setState({token_period: event.target.value}, () => this.toggleFormChanged(true));
  };

  onSubmit = () => {
    if (!this.formRef.current.validateForm()) {
      return;
    }
    let data = {
      assignment: {
        enable_test: this.state.enable_test,
        enable_student_tests: this.state.enable_student_tests,
        token_start_date: this.state.token_start_date,
        token_end_date: this.state.token_end_date,
        tokens_per_period: this.state.tokens_per_period,
        token_period: this.state.token_period,
        non_regenerating_tokens: this.state.non_regenerating_tokens,
        unlimited_tokens: this.state.unlimited_tokens,
      },
      schema_form_data: this.state.formData,
    };
    this.setState({form_changed: false, submitted: true});
    $.post({
      url: Routes.course_assignment_automated_tests_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: JSON.stringify(data),
      processData: false,
      contentType: "application/json",
    }).then(res => {
      poll_job(res["job_id"], this.fetchData);
    });
  };

  getDownloadAllURL = () => {
    return Routes.download_files_course_assignment_automated_tests_path(
      this.props.course_id,
      this.props.assignment_id
    );
  };

  specsDownloadURL = () => {
    return Routes.download_specs_course_assignment_automated_tests_path(
      this.props.course_id,
      this.props.assignment_id
    );
  };

  onSpecUploadModal = () => {
    this.setState({showSpecUploadModal: true});
  };

  handleUploadSpecFile = file => {
    this.setState({showSpecUploadModal: false});
    let data = new FormData();
    data.append("specs_file", file);
    $.post({
      url: Routes.upload_specs_course_assignment_automated_tests_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: data,
      processData: false, // tell jQuery not to process the data
      contentType: false, // tell jQuery not to set contentType
    })
      .then(this.fetchData())
      .then(() => this.toggleFormChanged(false))
      .then(this.endAction);
  };

  studentTestsField = () => {
    return (
      <fieldset>
        <legend>
          <span>{I18n.t("automated_tests.student_tests")}</span>
        </legend>
        <div className="inline-labels">
          <label className="inline_label" htmlFor="enable_student_tests">
            {I18n.t("activerecord.attributes.assignment.enable_student_tests")}
          </label>
          <input
            id="enable_student_tests"
            type="checkbox"
            checked={this.state.enable_student_tests}
            onChange={this.toggleEnableStudentTest}
            disabled={!this.state.enable_test}
          />
          <label className="inline_label" htmlFor="tokens_per_period">
            {I18n.t("activerecord.attributes.assignment.tokens_per_period")}
          </label>
          <span>
            <input
              id="tokens_per_period"
              type="number"
              min="0"
              value={this.state.tokens_per_period}
              onChange={this.handleTokensPerPeriodChange}
              disabled={
                this.state.unlimited_tokens ||
                !this.state.enable_test ||
                !this.state.enable_student_tests
              }
              style={{marginRight: "1em"}}
            />
            <span>
              (
              <label className="inline_label" style={{minWidth: 0}} htmlFor="unlimited_tokens">
                {I18n.t("activerecord.attributes.assignment.unlimited_tokens")}
                <input
                  id="unlimited_tokens"
                  type="checkbox"
                  checked={this.state.unlimited_tokens}
                  onChange={this.toggleUnlimitedTokens}
                  disabled={!this.state.enable_test || !this.state.enable_student_tests}
                  style={{marginLeft: "0.5em"}}
                />
              </label>
              )
            </span>
          </span>

          <label className="inline_label" htmlFor="token_start_date">
            {I18n.t("activerecord.attributes.assignment.token_start_date")}
          </label>
          <Flatpickr
            id="token_start_date"
            value={this.state.token_start_date}
            onChange={this.handleTokenStartDateChange}
            options={{
              altInput: true,
              altFormat: I18n.t("time.format_string.flatpickr"),
              dateFormat: "Z",
              disabled: !this.state.enable_test || !this.state.enable_student_tests,
              enableTime: true,
              plugins: [labelPlugin()], // Ensure id is applied to visible input
              showMonths: 2,
            }}
          />
          <label className="inline_label" htmlFor="token_end_date">
            {I18n.t("activerecord.attributes.assignment.token_end_date")}
          </label>
          <Flatpickr
            id="token_end_date"
            value={this.state.token_end_date}
            onChange={this.handleTokenEndDateChange}
            placeholder={I18n.t("automated_tests.use_assignment_due_date")}
            options={{
              altInput: true,
              altFormat: I18n.t("time.format_string.flatpickr"),
              dateFormat: "Z",
              disabled: !this.state.enable_test || !this.state.enable_student_tests,
              plugins: [labelPlugin()], // Ensure id is applied to visible input
            }}
          />
          <label className="inline_label" htmlFor="token_period">
            {I18n.t("activerecord.attributes.assignment.token_period")}
          </label>
          <span>
            <input
              id="token_period"
              type="number"
              min="0"
              step="0.01"
              value={this.state.token_period}
              onChange={this.handleTokenPeriodChange}
              disabled={
                this.state.unlimited_tokens ||
                this.state.non_regenerating_tokens ||
                !this.state.enable_test ||
                !this.state.enable_student_tests
              }
              style={{marginRight: "1em"}}
            />
            {I18n.t("durations.any_hours")}
            <span style={{marginLeft: "1em"}}>
              <label className="inline_label">
                ({I18n.t("activerecord.attributes.assignment.non_regenerating_tokens")}
                <input
                  id="non_regenerating_tokens"
                  type="checkbox"
                  checked={this.state.non_regenerating_tokens}
                  onChange={this.toggleNonRegeneratingTokens}
                  disabled={!this.state.enable_test || !this.state.enable_student_tests}
                  style={{marginLeft: "0.5em"}}
                />
                )
              </label>
            </span>
          </span>
        </div>
      </fieldset>
    );
  };

  render() {
    return (
      <div>
        <div className="inline-labels">
          <label>
            <input
              type="checkbox"
              checked={this.state.enable_test}
              onChange={this.toggleEnableTest}
            />
            {I18n.t("activerecord.attributes.assignment.enable_test")}
          </label>
        </div>
        <fieldset>
          <legend>
            <span>{I18n.t("automated_tests.files")}</span>
          </legend>
          <FileManager
            files={this.state.files}
            noFilesMessage={I18n.t("submissions.no_files_available")}
            readOnly={!this.state.enable_test}
            onCreateFiles={this.handleCreateFiles}
            onDeleteFile={this.handleDeleteFile}
            onCreateFolder={this.handleCreateFolder}
            onRenameFolder={typeof this.handleCreateFolder === "function" ? () => {} : undefined}
            onDeleteFolder={this.handleDeleteFolder}
            onActionBarAddFileClick={this.openUploadModal}
            downloadAllURL={this.getDownloadAllURL()}
            disableActions={{rename: true}}
          />
        </fieldset>
        <fieldset>
          <legend>
            <span>{I18n.t("automated_tests.tester", {count: 2})}</span>
          </legend>
          <div className={"rt-action-box upload-download"}>
            <a href={this.specsDownloadURL()} className={"button"}>
              <FontAwesomeIcon icon="fa-solid fa-download" />
              {I18n.t("download")}
            </a>
            <a onClick={this.onSpecUploadModal} className={"button"}>
              <FontAwesomeIcon icon="fa-solid fa-upload" />
              {I18n.t("upload")}
            </a>
          </div>
          <Form
            disabled={!this.state.enable_test}
            schema={this.state.schema}
            uiSchema={this.state.uiSchema}
            formData={this.state.formData}
            onChange={this.handleFormChange}
            validator={validator}
            templates={{
              ErrorListTemplate: AutotestErrorList,
              ButtonTemplates: {
                AddButton,
                MoveDownButton,
                MoveUpButton,
                RemoveButton,
              },
            }}
            ref={this.formRef}
          >
            <p /> {/*need something here so that the form doesn't render its own submit button*/}
          </Form>
        </fieldset>
        {this.studentTestsField()}
        <p>
          <input
            type="submit"
            value={this.state.submitted ? I18n.t("working") : I18n.t("save")}
            onClick={this.onSubmit}
            disabled={!this.state.form_changed}
          ></input>
        </p>
        <FileUploadModal
          isOpen={this.state.showFileUploadModal}
          onRequestClose={() =>
            this.setState({
              showFileUploadModal: false,
              uploadTarget: undefined,
            })
          }
          onSubmit={this.handleCreateFiles}
        />
        <AutotestSpecsUploadModal
          isOpen={this.state.showSpecUploadModal}
          onRequestClose={() => this.setState({showSpecUploadModal: false})}
          onSubmit={this.handleUploadSpecFile}
        />
      </div>
    );
  }
}

class AutotestErrorList extends React.Component {
  render() {
    return (
      <p className={"error"}>
        <FontAwesomeIcon icon="fa-solid fa-circle-exclamation" className="icon-left" />
        {I18n.t("automated_tests.errors.settings_invalid")}
      </p>
    );
  }
}

// Custom button templates to use Font Awesome
function AddButton(props) {
  const {
    uiSchema,
    registry: {translateString},
    ...btnProps
  } = props;
  let label = (uiSchema.items && uiSchema.items["ui:title"]) || "";
  if (label) {
    label = `${I18n.t("add")} ${label}`;
  }
  return (
    <div className="row">
      <p className={`col-xs-3 col-xs-offset-9 text-right`}>
        <button
          type="button"
          className={`btn btn-info btn-add col-xs-12`}
          title={label || translateString(TranslatableString.AddButton)}
          {...btnProps}
        >
          {label || <FontAwesomeIcon icon="fa-solid fa-add" />}
        </button>
      </p>
    </div>
  );
}

function RemoveButton(props) {
  const {
    uiSchema,
    registry: {translateString},
    ...btnProps
  } = props;
  return (
    <button
      type="button"
      className={`btn btn-danger array-item-remove`}
      title={translateString(TranslatableString.RemoveButton)}
      {...btnProps}
    >
      <FontAwesomeIcon icon="fa-solid fa-close" />
    </button>
  );
}

function MoveDownButton(props) {
  const {
    uiSchema,
    registry: {translateString},
    ...btnProps
  } = props;
  return (
    <button
      type="button"
      className={`btn btn-default array-item-move-down`}
      title={translateString(TranslatableString.MoveDownButton)}
      {...btnProps}
    >
      <FontAwesomeIcon icon="fa-solid fa-arrow-down" />
    </button>
  );
}

function MoveUpButton(props) {
  const {
    uiSchema,
    registry: {translateString},
    ...btnProps
  } = props;
  return (
    <button
      type="button"
      className={`btn btn-default array-item-move-up`}
      title={translateString(TranslatableString.MoveUpButton)}
      {...btnProps}
    >
      <FontAwesomeIcon icon="fa-solid fa-arrow-up" />
    </button>
  );
}

export function makeAutotestManager(elem, props) {
  const root = createRoot(elem);
  const component = React.createRef();
  root.render(<AutotestManager {...props} ref={component} />);
  return component;
}
