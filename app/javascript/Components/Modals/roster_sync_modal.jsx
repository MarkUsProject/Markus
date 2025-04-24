import React from "react";
import Modal from "react-modal";

class LtiRosterModal extends React.Component {
  static defaultProps = {};

  constructor(props) {
    super(props);
    this.state = {
      include_tas: true,
      include_students: true,
      include_instructors: true,
      automatic_sync: true,
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
    const value = target.type === "checkbox" ? target.checked : target.value;
    this.setState({[target.name]: value});
  };

  syncRoster = () => {
    $.post({
      url: Routes.sync_roster_course_path(this.props.course_id),
      data: {
        include_students: this.state.include_students,
        include_tas: this.state.include_tas,
        include_instructors: this.state.include_instructors,
        automatic_sync: this.state.automatic_sync,
        lti_deployment_id: this.props.roster_deployment_id,
      },
    });
  };

  render() {
    return (
      <div>
        <Modal
          className="react-modal markus-dialog"
          isOpen={this.props.isOpen}
          onRequestClose={this.props.onRequestClose}
        >
          <h2>{I18n.t("lti.roster_sync")}</h2>
          <form onSubmit={this.onSubmit}>
            <div className={"modal-container-vertical"}>
              <p>{I18n.t("lti.roster_sync_instructions")}</p>
              <p>
                <label>
                  <input
                    type="checkbox"
                    name="include_students"
                    key="1"
                    defaultChecked="true"
                    onChange={this.handleChange}
                  />
                  {I18n.t("lti.sync_students")}
                </label>
              </p>
              <p>
                <label>
                  <input
                    type="checkbox"
                    name="include_tas"
                    key="2"
                    defaultChecked="true"
                    onChange={this.handleChange}
                  />
                  {I18n.t("lti.sync_tas")}
                </label>
              </p>
              <p>
                <label>
                  <input
                    type="checkbox"
                    name="include_instructors"
                    key="3"
                    defaultChecked="true"
                    onChange={this.handleChange}
                  />
                  {I18n.t("lti.sync_instructors")}
                </label>
              </p>
              <p>
                <label>
                  <input
                    type="checkbox"
                    name="automatic_sync"
                    key="4"
                    defaultChecked="true"
                    onChange={this.handleChange}
                  />
                  {I18n.t("lti.sync_automatically")}
                </label>
              </p>

              <section className={"modal-container dialog-actions"}>
                <input type="submit" value={I18n.t("lti.roster_sync")} />
              </section>
            </div>
          </form>
        </Modal>
      </div>
    );
  }
}

export default LtiRosterModal;
