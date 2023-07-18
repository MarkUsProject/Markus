import React from "react";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export class RangeFilter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {showErrorMessage: false};
  }

  renderErrorMessage = () => {
    return (
      <div className={"range"}>
        <FontAwesomeIcon icon={"fa-solid fa-circle-exclamation"} />
        <span className={"validity"}>{I18n.t("results.filters.invalid_range")}</span>
      </div>
    );
  };

  componentDidUpdate(prevProps) {
    if (prevProps !== this.props) {
      if (this.props.min === "" && this.props.max === "") {
        this.setState({showErrorMessage: false});
      }
    }
  }

  render() {
    let min = this.props.min;
    let max = this.props.max;
    let title = this.props.title;

    return (
      <div className={"filter"}>
        <p>{title}</p>
        <div className={"range"} onChange={e => this.handleInputs(e)} data-testid={title}>
          <input
            className={"input-min"}
            type="number"
            step="0.01"
            placeholder={"Min"}
            value={min}
            max={max}
            onChange={() => {}}
          />
          <span>{I18n.t("results.filters.range_value_separator")}</span>
          <input
            className={"input-max"}
            type="number"
            step="0.01"
            placeholder={"Max"}
            value={max}
            min={min}
            onChange={() => {}}
          />
          {this.state.showErrorMessage && this.renderErrorMessage()}
        </div>
      </div>
    );
  }

  handleInputs = e => {
    this.setState({showErrorMessage: !e.target.validity.valid});
    this.props.handleInputs(e);
  };
}
