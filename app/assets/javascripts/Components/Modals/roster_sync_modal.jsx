import React from "react";
import Modal from "react-modal";

class LtiRosterModal extends React.Component {
  static defaultProps = {};

  constructor(props) {
    super(props);
    this.state = {
      tas: true,
      students: true,
      isOpen: false,
      showLtiRosterModal: false,
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    this.syncRoster();
    this.props.onRequestClose();
  };

  handleChange = event => {
    const target = event.target;
    //const target_name = target.name;
    const value = target.type === "checkbox" ? target.checked : target.value;
    this.setState({[target.name]: value});
  };

  syncRoster = () => {
    $.post({
      url: Routes.sync_roster_course_path(this.props.course_id),
      data: {
        students: this.state.students,
        tas: this.state.tas,
        lti_deployment_id: this.props.roster_id,
      },
    });
  };
  render() {
    return (
      <div>
        <Modal
          className="react-modal dialog"
          isOpen={this.props.isOpen}
          onRequestClose={this.props.onRequestClose}
          rosterID={this.props.rosterId}
        >
          <h2>{I18n.t("lti.sync_grades_lms")}</h2>
          <form onSubmit={this.onSubmit}>
            <div className={"modal-container-vertical"}>
              <p>{I18n.t("lti.grade_sync_instructions")}</p>
              <p>
                <label>
                  <input
                    type="checkbox"
                    name="students"
                    key="1"
                    defaultChecked="true"
                    onChange={this.handleChange}
                  />
                  "Students"
                </label>
              </p>
              <p>
                <label>
                  <input
                    type="checkbox"
                    name="tas"
                    key="2"
                    defaultChecked="true"
                    onChange={this.handleChange}
                  />
                  "TAs"
                </label>
              </p>

              <section className={"modal-container dialog-actions"}>
                <input type="submit" value={I18n.t("lti.sync_grades")} />
              </section>
            </div>
          </form>
        </Modal>
      </div>
    );
  }
}

export default LtiRosterModal;
