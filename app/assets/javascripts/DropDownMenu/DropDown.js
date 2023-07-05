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

  renderArrow = () => {
    if (this.state.expanded !== false) {
      return <span className="arrow-up" />;
    } else {
      return <span className="arrow-down" />;
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
      >
        <a>{this.props.selected}</a>
        <div className="options">
          <div
            className="reset"
            onClick={e => {
              e.preventDefault();
              this.select(e, this.props.defaultValue);
            }}
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
