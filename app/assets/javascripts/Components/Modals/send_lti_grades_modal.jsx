import React from "react";
import Modal from "react-modal";

class LtiGradeModal extends React.Component {
  static defaultProps = {
    override: false,
  };

  constructor(props) {
    super(props);
    this.state = {
      deploymentsChecked: undefined,
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
    const deploymentsMapped = this.props.lti_deployments.map(deployment => ({
      deployment: deployment.id,
      checked: true,
    }));
    this.setState({deploymentsChecked: deploymentsMapped});
  }

  onSubmit = event => {
    event.preventDefault();
    this.sendLtiGrades();
    this.props.onRequestClose();
  };

  handleChange = event => {
    const target = event.target;
    const value = target.type === "checkbox" ? target.checked : target.value;
    const deployment_id = target.name;
    let deploymentsSettings = this.state.deploymentsChecked;
    let setting = deploymentsSettings.find(deployment => deployment.deployment == deployment_id);
    setting.checked = value;
    this.setState({deploymentsChecked: deploymentsSettings});
  };

  sendLtiGrades = () => {
    const checked = this.state.deploymentsChecked.filter(deployment => deployment.checked);
    const deploymentsToUpdate = checked.map(deployment => deployment.deployment);
    $.post({
      url: Routes.lti_deployment_create_lti_grades_path(),
      data: {
        assessment_id: this.props.assignment_id,
        lti_deployments: deploymentsToUpdate,
      },
    });
  };
  render() {
    return (
      <Modal
        className="react-modal dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <h2>{I18n.t("lti.sync_grades_lms")}</h2>
        <form onSubmit={this.onSubmit}>
          <div className={"modal-container-vertical"}>
            <p>{I18n.t("lti.grade_sync_instructions")}</p>
            {this.props.lti_deployments.map(deployment => {
              return (
                <p>
                  <label>
                    <input
                      type="checkbox"
                      name={deployment.id}
                      key={deployment.id}
                      defaultChecked="true"
                      onChange={this.handleChange}
                    />
                    {I18n.t("lti.lti_deployment", {
                      lti_deployment_name: deployment.lms_course_name,
                      lti_host: deployment.host,
                    })}
                  </label>
                </p>
              );
            })}

            <section className={"modal-container dialog-actions"}>
              <input type="submit" value={I18n.t("lti.sync_grades")} />
            </section>
          </div>
        </form>
      </Modal>
    );
  }
}

export default LtiGradeModal;
