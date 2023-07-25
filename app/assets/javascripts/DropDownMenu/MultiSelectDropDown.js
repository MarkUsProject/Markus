import React from "react";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export class MultiSelectDropdown extends React.Component {
  constructor(props) {
    super(props);
    this.state = {expanded: false, tags: []};
  }

  onClickOutside = e => {
    this.setState({expanded: false});
  };

  onSelect = (e, option) => {
    e.stopPropagation();
    this.props.onToggleOption(option);
  };

  renderDropdown = (options, selected, expanded) => {
    let isSelected;
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
                  <input
                    id={option.key}
                    type="checkbox"
                    checked={isSelected}
                    onChange={() => null}
                  ></input>
                  <label htmlFor={option.key} onClick={event => event.preventDefault()}>
                    {option.display}
                  </label>
                </li>
              );
            })}
          </ul>
        );
      }
    }
  };

  render() {
    let selected = this.props.selected;
    let options = this.props.options;
    let expanded = this.state.expanded;
    let arrow;
    if (expanded !== false) {
      arrow = <span className="arrow-up" />;
    } else {
      arrow = <span className="arrow-down" />;
    }

    return (
      <div
        className="multiselect-dropdown"
        onClick={() => this.setState({expanded: !this.state.expanded})}
        data-testid={this.props.title}
        tabIndex={-1}
        onBlur={this.onClickOutside}
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
        <div className={"options"}>
          <div
            className="float-right"
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
