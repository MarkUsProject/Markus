import React from "react";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export class MultiSelectDropdown extends React.Component {
  constructor(props) {
    super(props);
    this.state = {expanded: false, tags: []};
  }

  select = (e, title) => {
    e.stopPropagation();
    this.props.toggleOption({title});
  };

  renderDropdown = (options, selected, expanded) => {
    let isSelected;
    if (expanded) {
      return (
        <ul
          style={{
            display: "block",
            boxShadow: "0px 4px 14px rgba(0, 0, 0, 0.10)",
            borderRadius: 8,
            gap: 1,
          }}
        >
          {options.map(option => {
            isSelected = selected.includes(option.title);
            return (
              <li
                key={option.title}
                style={{alignSelf: "stretch"}}
                onClick={e => this.select(e, option.title)}
              >
                <input type="checkbox" checked={isSelected} onChange={() => null}></input>
                <span style={{margin: "0.25em"}}>{option.title}</span>
              </li>
            );
          })}
        </ul>
      );
    }
  };

  render() {
    console.log("hello");
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
        className="dropdown"
        style={{boxShadow: "0px 4px 14px rgba(0, 0, 0, 0.10)", borderRadius: 8, gap: 1}}
        onClick={() => this.setState({expanded: !this.state.expanded})}
        onBlur={() => this.setState({expanded: false})}
        tabIndex={-1}
      >
        <div
          style={{flexWrap: "wrap", display: "inline-flex", overflow: "hidden", padding: "0, 0"}}
        >
          {selected.map((tag, index) => (
            <tag
              className="tag"
              key={index}
              onClick={e => {
                e.preventDefault();
                this.select(e, tag);
              }}
            >
              <span style={{margin: "0.25em"}}>{tag}</span>
              <FontAwesomeIcon icon="fa-solid fa-xmark" />
            </tag>
          ))}
        </div>
        {arrow}
        {expanded && this.renderDropdown(options, selected, expanded)}
      </div>
    );
  }
}
