import React from "react";

import safe_marked from "../../common/safe_marked";

export class DropDownMenu extends React.Component {
  constructor(props) {
    super(props);
    this.state = {expanded: false};
  }

  handleMouseEnter = () => {
    this.setState({expanded: true});
  };

  handleMouseLeave = () => {
    this.setState({expanded: false});
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

        {this.state.expanded && (
          <ul>
            {this.props.items.map(item => (
              <li
                key={item.id}
                data-testid={`item-${item.id}`}
                onClick={e => {
                  e.preventDefault();
                  this.props.addExistingAnnotation(item.id);
                }}
              >
                <span
                  className={"text-content"}
                  dangerouslySetInnerHTML={{__html: safe_marked(item.content).slice(0, 70)}}
                />
                <span className={"red-text"}>{!item.deduction ? "" : "-" + item.deduction}</span>
              </li>
            ))}
          </ul>
        )}
      </li>
    );
  }
}
