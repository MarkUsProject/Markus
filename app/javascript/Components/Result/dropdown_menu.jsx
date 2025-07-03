import React from "react";

export class DropDownMenu extends React.Component {
  constructor(props) {
    super(props);
    this.state = {hoveredCatId: null};
  }

  handleMouseEnter = catId => {
    this.setState({hoveredCatId: catId});
  };

  handleMouseLeave = () => {
    this.setState({hoveredCatId: null});
  };

  render() {
    return (
      <ul className="tags" key="annotation_categories">
        {this.props.categories.map(cat => (
          <li
            className="annotation_category"
            id={`annotation_category_${cat.id}`}
            key={cat.id}
            onMouseEnter={this.handleMouseEnter}
            onMouseLeave={this.handleMouseLeave}
            onMouseDown={e => e.preventDefault()}
          >
            {this.state.hoveredCatId === cat.id && (
              <div id={`annotation_text_list_${cat.id}`}>
                <ul>
                  {cat.texts.map(text => (
                    <li
                      key={`annotation_text_${text.id}`}
                      id={`annotation_text_${text.id}`}
                      onClick={e => {
                        e.preventDefault();
                        this.props.addExistingAnnotation(text.id);
                      }}
                      onMouseDown={e => e.preventDefault()}
                      title={text.content}
                    >
                      <span
                        className={"text-content"}
                        dangerouslySetInnerHTML={{__html: safe_marked(text.content).slice(0, 70)}}
                      />
                      <span className={"red-text"}>
                        {!text.deduction ? "" : "-" + text.deduction}
                      </span>
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </li>
        ))}
      </ul>
    );
  }
}
