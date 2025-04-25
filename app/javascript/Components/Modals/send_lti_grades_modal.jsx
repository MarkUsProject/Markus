import React from "react";
import Modal from "react-modal";

class LtiGradeModal extends React.Component {
  static defaultProps = {};

  constructor(props) {
    super(props);
    this.state = {
      deploymentsChecked: {},
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
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
    const deploymentsSettings = this.state.deploymentsChecked;
    deploymentsSettings[deployment_id] = value;
    this.setState({deploymentsChecked: deploymentsSettings});
  };

  sendLtiGrades = () => {
    const checked = Object.entries(this.state.deploymentsChecked).filter(
      deployment => deployment[1] == true
    );
    const deploymentsToUpdate = checked.map(deployment => deployment[0]);
    $.post({
      url: Routes.create_lti_grades_course_assignment_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {
        assessment_id: this.props.assignment_id,
        lti_deployments: deploymentsToUpdate,
      },
    });
  };
  render() {
    return (
      <Modal
        className="react-modal markus-dialog"
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
