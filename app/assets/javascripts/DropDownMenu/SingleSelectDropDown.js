import React from "react";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export class SingleSelectDropDown extends React.Component {
  constructor(props) {
    super(props);
    this.state = {expanded: false};
  }

  select = (e, selection) => {
    e.stopPropagation();
    this.props.select(selection);
    this.setState({expanded: false});
  };

  renderDropdown = (options, selected, expanded) => {
    if (expanded) {
      if (options.length === 0) {
        return (
          <ul>
            <li>
              <span>{I18n.t("results.filters.no_options")}</span>
            </li>
          </ul>
        );
      } else {
        return (
          <ul data-testid={"options"}>
            {options.map(option => {
              return (
                <li
                  key={option}
                  style={{alignSelf: "stretch"}}
                  onClick={e => this.select(e, option)}
                >
                  <span>{option}</span>
                </li>
              );
            })}
          </ul>
        );
      }
    }
  };

  renderArrow = () => {
    if (this.state.expanded !== false) {
      return <span className="arrow-up" data-testid={"arrow-up"} />;
    } else {
      return <span className="arrow-down" data-testid={"arrow-down"} />;
    }
  };

  render() {
    let selected = this.props.selected;
    let options = this.props.options;
    let expanded = this.state.expanded;

    return (
      <div
        className="singleselect-dropdown"
        onClick={() => this.setState({expanded: !this.state.expanded})}
        onBlur={() => this.setState({expanded: false})}
        tabIndex={-1}
        data-testid={"dropdown"}
      >
        <a data-testid={"selection"}>{this.props.selected}</a>
        <div className="options">
          <div
            className="reset"
            onClick={e => {
              e.preventDefault();
              this.select(e, this.props.defaultValue);
            }}
            data-testid={"reset-dropdown-selection"}
          >
            <FontAwesomeIcon icon="fa-solid fa-xmark" style={{color: "#255185"}} />
          </div>
          {this.renderArrow()}
        </div>
        {expanded && this.renderDropdown(options, selected, expanded)}
      </div>
    );
  }
}
