import React from "react";
import {DropDownMenu} from "./dropdown_menu";

export class AnnotationManager extends React.Component {
  render() {
    return (
      <React.Fragment>
        <button key="new_annotation_button" onClick={this.props.newAnnotation} title="Shift + N">
          {I18n.t("helpers.submit.create", {
            model: I18n.t("activerecord.models.annotation.one"),
          })}
        </button>
        <ul className="tags" key="annotation_categories">
          {this.props.categories.map(cat => (
            <DropDownMenu
              key={cat.id}
              header={cat.annotation_category_name}
              items={cat.texts}
              onItemClick={this.props.addExistingAnnotation}
            />
          ))}
        </ul>
      </React.Fragment>
    );
  }
}
``;
