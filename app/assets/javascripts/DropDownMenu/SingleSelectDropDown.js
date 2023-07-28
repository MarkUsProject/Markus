import React from "react";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export class SingleSelectDropDown extends React.Component {
  constructor(props) {
    super(props);
    this.state = {expanded: false};
  }

  onSelect = (e, selection) => {
    e.stopPropagation();
    this.props.onSelect(selection);
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
                <li key={option} onClick={e => this.onSelect(e, option)}>
                  <span>
                    {this.props.valueToDisplayName != null
                      ? this.props.valueToDisplayName[option]
                      : option}
                  </span>
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
        className="dropdown single-select-dropdown"
        onClick={() => this.setState({expanded: !this.state.expanded})}
        onBlur={() => this.setState({expanded: false})}
        tabIndex={-1}
        data-testid={"dropdown"}
      >
        <a data-testid={"selection"}>
          {this.props.valueToDisplayName != null
            ? this.props.valueToDisplayName[this.props.selected]
            : this.props.selected}
        </a>
        {this.renderArrow()}
        <div
          className="float-right"
          onClick={e => {
            e.preventDefault();
            this.onSelect(e, this.props.defaultValue);
          }}
          data-testid={"reset-dropdown-selection"}
        >
          <FontAwesomeIcon icon="fa-solid fa-xmark" className={"x-mark"} />
        </div>

        {expanded && this.renderDropdown(options, selected, expanded)}
      </div>
    );
  }
}
