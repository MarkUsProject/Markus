import React from "react";
import PropTypes from "prop-types";

import safe_marked from "../../common/safe_marked";

export class DropDownMenu extends React.Component {
  constructor(props) {
    super(props);
    this.state = {onHover: false};
  }

  handleMouseEnter = () => {
    this.setState({onHover: true});
  };

  handleMouseLeave = () => {
    this.setState({onHover: false});
  };

  render() {
    return (
      <li
        className="dropdown_menu"
        onMouseEnter={this.handleMouseEnter}
        onMouseLeave={this.handleMouseLeave}
        onMouseDown={e => e.preventDefault()}
      >
        <div className="dropdown-header">{this.props.header}</div>

        {this.state.onHover && (
          <div className="list">
            <ul>
              {this.props.items.map(item => (
                <li
                  key={item.id}
                  id={item.id}
                  data-testid={`item-${item.id}`}
                  onMouseEnter={() => this.props.addExistingAnnotation(item.id)}
                  onMouseDown={e => e.preventDefault()}
                  title={item.content}
                >
                  <span
                    className={"text-content"}
                    dangerouslySetInnerHTML={{__html: safe_marked(item.content).slice(0, 70)}}
                  />
                  <span className={"red-text"}>{!item.deduction ? "" : "-" + item.deduction}</span>
                </li>
              ))}
            </ul>
          </div>
        )}
      </li>
    );
  }
}
