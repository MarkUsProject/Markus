import React from "react";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export class MultiSelectDropdown extends React.Component {
  constructor(props) {
    super(props);
    this.state = {expanded: false, tags: []};
    this.dropdownRef = React.createRef();
  }

  componentDidMount() {
    document.addEventListener("mousedown", this.handleClickOutside);
  }

  componentWillUnmount() {
    document.removeEventListener("mousedown", this.handleClickOutside);
  }

  handleClickOutside = event => {
    // Check if the click is outside the dropdown container
    if (this.dropdownRef.current && !this.dropdownRef.current.contains(event.target)) {
      this.setState({expanded: false});
    }
  };

  select = (e, option) => {
    e.stopPropagation();
    this.props.toggleOption(option);
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
              isSelected = selected.includes(option);
              return (
                <li key={option} onClick={e => this.select(e, option)}>
                  <input
                    type="checkbox"
                    id={option}
                    checked={isSelected}
                    onChange={() => null}
                  ></input>
                  <label htmlFor={option} onClick={event => event.preventDefault()}>
                    {option}
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
        data-testid={this.props.id}
        ref={this.dropdownRef}
      >
        <div className={"tags-box"} data-testid={"tags-box"}>
          {selected.map((tag, index) => (
            <div
              className="tag"
              key={index}
              onClick={e => {
                this.select(e, tag);
              }}
            >
              <span>{tag}</span>
              <FontAwesomeIcon icon="fa-solid fa-xmark" />
            </div>
          ))}
        </div>
        {arrow}
        <div
          className="reset"
          data-testid={"reset"}
          onClick={e => {
            e.preventDefault();
            e.stopPropagation();
            this.props.clearSelection();
          }}
        >
          <FontAwesomeIcon icon="fa-solid fa-xmark" />
        </div>
        {expanded && this.renderDropdown(options, selected, expanded)}
      </div>
    );
  }
}
