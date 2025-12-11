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

  renderDropdown = (options, selected, expanded, disabled) => {
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
              if (disabled && disabled.includes(option)) {
                return (
                  <li key={option} className={"disabled"}>
                    <span>
                      {this.props.valueToDisplayName != null
                        ? this.props.valueToDisplayName[option]
                        : option}
                    </span>
                  </li>
                );
              } else {
                return (
                  <li key={option} onClick={e => this.onSelect(e, option)}>
                    <span>
                      {this.props.valueToDisplayName != null
                        ? this.props.valueToDisplayName[option]
                        : option}
                    </span>
                  </li>
                );
              }
            })}
          </ul>
        );
      }
    }
  };

  renderArrow = () => {
    if (this.state.expanded !== false) {
      return <FontAwesomeIcon className="arrow-up" icon="fa-chevron-up" data-testid={"arrow-up"} />;
    } else {
      return (
        <FontAwesomeIcon className="arrow-down" icon="fa-chevron-down" data-testid={"arrow-down"} />
      );
    }
  };

  render() {
    let selected = this.props.selected;
    let options = this.props.options;
    let expanded = this.state.expanded;
    let disabled = this.props.disabled;

    return (
      <div
        className="dropdown single-select-dropdown"
        style={this.props.dropdownStyle}
        onClick={() => this.setState({expanded: !this.state.expanded})}
        onBlur={() => this.setState({expanded: false})}
        tabIndex={-1}
        data-testid={"dropdown"}
      >
        <a data-testid={"selection"} style={this.props.selectionStyle}>
          {this.props.valueToDisplayName != null
            ? this.props.valueToDisplayName[this.props.selected]
            : this.props.selected}
        </a>
        {this.renderArrow()}
        {!this.props.hideXMark && (
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
        )}
        {expanded && this.renderDropdown(options, selected, expanded, disabled)}
      </div>
    );
  }
}
