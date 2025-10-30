import React from "react";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export class MultiSelectDropdown extends React.Component {
  constructor(props) {
    super(props);
    this.state = {expanded: false, tags: []};
  }

  onSelect = (e, option) => {
    e.stopPropagation();
    this.props.onToggleOption(option);
  };

  renderDropdown = (options, selected, expanded) => {
    let isSelected;
    options.sort((a, b) => a.key.localeCompare(b.key));
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
          <ul>
            {options.map(option => {
              isSelected = selected.includes(option.key);
              return (
                <li key={option.key} onClick={e => this.onSelect(e, option.key)}>
                  {this.renderCheckBox(isSelected)}
                  <span>{option.display}</span>
                </li>
              );
            })}
          </ul>
        );
      }
    }
  };

  renderCheckBox = checked => {
    if (checked) {
      return (
        <div data-testid={"checked"}>
          <FontAwesomeIcon icon="fa-solid fa-square-check" />
        </div>
      );
    } else {
      return (
        <div data-testid={"unchecked"}>
          <FontAwesomeIcon icon="fa-regular fa-square" />
        </div>
      );
    }
  };

  render() {
    let selected = this.props.selected;
    let options = this.props.options;
    let expanded = this.state.expanded;
    let arrow;
    if (expanded !== false) {
      arrow = <FontAwesomeIcon className="arrow-up" icon="fa-chevron-up" />;
    } else {
      arrow = <FontAwesomeIcon className="arrow-down" icon="fa-chevron-down" />;
    }

    return (
      <div
        className="dropdown multi-select-dropdown"
        onClick={() => this.setState({expanded: !this.state.expanded})}
        data-testid={this.props.title}
        tabIndex={-1}
        onBlur={() => this.setState({expanded: false})}
      >
        <div className={"tags-box"} data-testid={"tags-box"}>
          {selected.map(tag => (
            <div
              className="tag"
              onClick={e => {
                this.onSelect(e, tag);
              }}
            >
              <span>{tag}</span>
              <FontAwesomeIcon icon="fa-solid fa-xmark" />
            </div>
          ))}
        </div>
        <div className={"options float-right"}>
          <div
            data-testid={"reset"}
            onClick={e => {
              e.preventDefault();
              e.stopPropagation();
              this.props.onClearSelection();
            }}
          >
            <FontAwesomeIcon icon="fa-solid fa-xmark" />
          </div>
          {arrow}
        </div>
        {expanded && this.renderDropdown(options, selected, expanded)}
      </div>
    );
  }
}
