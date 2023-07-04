import React from "react";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export class MultiSelectDropdown extends React.Component {
  constructor(props) {
    super(props);
    this.state = {expanded: false, tags: []};
  }

  select = (e, option) => {
    e.stopPropagation();
    this.props.toggleOption(option);
  };

  renderDropdown = (options, selected, expanded) => {
    let isSelected;
    if (expanded) {
      return (
        <ul>
          {options.map(option => {
            isSelected = selected.includes(option);
            return (
              <li key={option} style={{alignSelf: "stretch"}} onClick={e => this.select(e, option)}>
                <input type="checkbox" checked={isSelected} onChange={() => null}></input>
                <span>{option}</span>
              </li>
            );
          })}
        </ul>
      );
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
        onBlur={() => this.setState({expanded: false})}
        tabIndex={-1}
      >
        <div className={"tags-box"}>
          {selected.map((tag, index) => (
            <div
              className="tag"
              key={index}
              onClick={e => {
                e.preventDefault();
                this.select(e, tag);
              }}
            >
              <span>{tag}</span>
              <FontAwesomeIcon icon="fa-solid fa-xmark" />
            </div>
          ))}
        </div>
        {arrow}
        {expanded && this.renderDropdown(options, selected, expanded)}
      </div>
    );
  }
}
