import React from "react";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export class Dropdown extends React.Component {
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
      return (
        <ul>
          {options.map(option => {
            return (
              <li key={option} style={{alignSelf: "stretch"}} onClick={e => this.select(e, option)}>
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
        className="singleselect-dropdown"
        onClick={() => this.setState({expanded: !this.state.expanded})}
        onBlur={() => this.setState({expanded: false})}
        tabIndex={-1}
      >
        <a>{this.props.selected}</a>
        <div
          className="reset"
          onClick={e => {
            e.preventDefault();
            this.select(e, "");
          }}
        >
          <FontAwesomeIcon icon="fa-solid fa-xmark" />
        </div>
        {arrow}
        {expanded && this.renderDropdown(options, selected, expanded)}
      </div>
    );
  }
}
