import React from "react";
import {createRoot} from "react-dom/client";
import Modal from "react-modal";

class SubmitViewTokenModal extends React.Component {
  constructor() {
    super();
    this.state = {
      isOpen: false,
      token: null,
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = () => {
    $.ajax({
      url: Routes.view_token_check_course_result_path(this.props.course_id, this.props.result_id, {
        view_token: this.state.token,
      }),
    }).then(
      () => {
        window.location = Routes.view_marks_course_result_path(
          this.props.course_id,
          this.props.result_id,
          {view_token: this.state.token}
        );
      },
      () => this.setState({isOpen: false, token: null})
    );
  };

  render() {
    return (
      <Modal
        className="react-modal"
        isOpen={this.state.isOpen}
        onRequestClose={() => this.setState({isOpen: false, token: null})}
      >
        <p>{I18n.t("results.view_token_submit")}</p>
        <form onSubmit={this.onSubmit}>
          <div className={"modal-container-vertical"}>
            <div className={"modal-container"}>
              <input onChange={e => this.setState({token: e.target.value})} />
            </div>
            <div className={"modal-container"}>
              <input type="submit" value={I18n.t("results.submit_token")} />
            </div>
          </div>
        </form>
      </Modal>
    );
  }
}

export function makeSubmitViewTokenModal(elem, props) {
  const root = createRoot(elem);
  const component = React.createRef();
  root.render(<SubmitViewTokenModal {...props} ref={component} />);
  return component;
}
