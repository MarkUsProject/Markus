import React from "react";
import Modal from "react-modal";

class ExtensionModal extends React.Component {
  static defaultProps = {
    weeks: 0,
    days: 0,
    hours: 0,
    minutes: 0,
    note: "",
    penalty: false,
    updating: false,
    times: [],
    title: "",
  };

  constructor(props) {
    super(props);
    this.state = {
      weeks: props.weeks,
      days: props.days,
      hours: props.hours,
      minutes: props.minutes,
      note: props.note,
      penalty: props.penalty,
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  stateHasChanged = () => {
    for (let s of Object.keys(this.state)) {
      if (this.state[s] !== this.props[s]) {
        return true;
      }
    }
    return false;
  };

  submitForm = event => {
    event.preventDefault();
    if (this.stateHasChanged()) {
      let data = {
        weeks: this.state.weeks,
        days: this.state.days,
        hours: this.state.hours,
        minutes: this.state.minutes,
        note: this.state.note,
        penalty: this.state.penalty,
        grouping_id: this.props.grouping_id,
      };
      if (!!this.props.extension_id) {
        $.ajax({
          type: "PUT",
          url: Routes.course_extension_path(this.props.course_id, this.props.extension_id),
          data: data,
        }).then(() => this.props.onRequestClose(true));
      } else {
        $.post({
          url: Routes.course_extensions_path(this.props.course_id),
          data: data,
        }).then(() => this.props.onRequestClose(true));
      }
    } else {
      this.props.onRequestClose(false);
    }
  };

  deleteExtension = event => {
    event.preventDefault();
    $.ajax({
      type: "DELETE",
      url: Routes.course_extension_path(this.props.course_id, this.props.extension_id),
    }).then(() => this.props.onRequestClose(true));
  };

  handleModalInputChange = event => {
    const target = event.target;
    const value = target.type === "checkbox" ? target.checked : target.value;
    const name = target.name;

    this.setState({
      [name]: value,
    });
  };

  getLabel = time => {
    // Return the internationalized version of +time+
    if (time === "weeks") {
      return I18n.t("durations.weeks.other");
    } else if (time === "days") {
      return I18n.t("durations.days.other");
    } else if (time === "hours") {
      return I18n.t("durations.hours.other");
    } else if (time === "minutes") {
      return I18n.t("durations.minutes.other");
    }
  };

  renderTimeInput = () => {
    // Render a label and input for each time in
    // this.props.times
    return this.props.times.map(time => (
      <label key={time}>
        <input
          type="number"
          value={this.state[time]}
          max={time === "minutes" ? 60 : 999}
          min={0}
          name={time}
          onChange={this.handleModalInputChange}
        />{" "}
        {this.getLabel(time)}
      </label>
    ));
  };

  renderExtraInfo = () => {
    // Render this.props.extra info if it exists
    if (!!this.props.extra_info) {
      return <div className={"modal-container"}>{this.props.extra_info}</div>;
    }
  };

  render() {
    return (
      <Modal
        className="react-modal markus-dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <h2>{this.props.title}</h2>
        <form onSubmit={this.submitForm}>
          <div className={"modal-container-vertical"}>
            <div className={"modal-container"}>{this.renderExtraInfo()}</div>
            <div className={"modal-container"}>{this.renderTimeInput()}</div>
            <br />
            <div>
              <label>
                <input
                  type="checkbox"
                  value={this.state.penalty}
                  checked={this.state.penalty}
                  name={"penalty"}
                  onChange={this.handleModalInputChange}
                />{" "}
                {I18n.t("extensions.apply_penalty")}
              </label>
            </div>
            <div>
              <label>
                <textarea
                  placeholder={I18n.t("activerecord.attributes.extensions.note") + "..."}
                  value={this.state.note}
                  name={"note"}
                  onChange={this.handleModalInputChange}
                />
              </label>
            </div>
            <div className={"modal-container"}>
              <input type="submit" value={I18n.t("save")} />
              <button onClick={this.deleteExtension} disabled={!this.props.updating}>
                {I18n.t("delete")}
              </button>
            </div>
          </div>
        </form>
      </Modal>
    );
  }
}

export default ExtensionModal;
