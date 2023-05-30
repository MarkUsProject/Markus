import React from "react";
import {render} from "react-dom";
import RosterSyncModal from "./Modals/roster_sync_modal";

class LtiSettings extends React.Component {
  constructor() {
    super();
    this.state = {
      deployments: [],
      showLtiRosterModal: false,
      external_roster_id: null,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    $.ajax({
      url: Routes.lti_deployments_course_path(this.props.course_id),
      dataType: "json",
    }).then(data => {
      this.setState({deployments: data});
    });
  };

  deleteDeployment = deployment_id => {
    if (confirm(I18n.t("lti.unlink_confirm"))) {
      $.ajax({
        url: Routes.destroy_lti_deployment_course_path(this.props.course_id),
        type: "DELETE",
        data: {lti_deployment_id: deployment_id},
      }).then(data => {
        this.setState({
          deployments: this.state.deployments.filter(deployment => deployment.id != deployment_id),
        });
      });
    }
  };

  onLtiRosterModal = deployment_id => {
    this.setState({showLtiRosterModal: true, external_roster_id: deployment_id});
  };

  render() {
    let ltiDeployments;
    let deleteDeployment = this.deleteDeployment.bind(this);
    let onLtiRosterModal = this.onLtiRosterModal.bind(this);
    if (this.state.deployments.length > 0) {
      ltiDeployments = this.state.deployments.map(function (deployment, i) {
        return (
          <div key={i}>
            {I18n.t("lti.lti_course_link_html")}{" "}
            <a href={deployment.lti_client.host + "/courses/" + deployment.lms_course_id}>
              {deployment.lms_course_name}
            </a>
            .
            <div>
              <button
                type="submit"
                name="sync_roster"
                onClick={() => onLtiRosterModal(deployment.id)}
              >
                {I18n.t("lti.roster_sync")}
              </button>
              <button type="submit" name="delete" onClick={() => deleteDeployment(deployment.id)}>
                {I18n.t("lti.unlink_courses")}
              </button>
            </div>
          </div>
        );
      });
    } else {
      ltiDeployments = <div>{I18n.t("lti.course_not_linked")}</div>;
    }
    return (
      <div>
        <h3>{I18n.t("lti.lti_configuration")}</h3>
        {ltiDeployments}
        <RosterSyncModal
          isOpen={this.state.showLtiRosterModal}
          onRequestClose={() => this.setState({showLtiRosterModal: false})}
          course_id={this.props.course_id}
          roster_id={this.state.external_roster_id}
        />
      </div>
    );
  }
}

export function makeLtiSettings(elem, props) {
  render(<LtiSettings {...props} />, elem);
}
