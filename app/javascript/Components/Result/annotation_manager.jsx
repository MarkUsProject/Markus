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

        <DropDownMenu
          categories={this.props.categories}
          addExistingAnnotation={this.props.addExistingAnnotation}
        />
      </React.Fragment>
    );
  }
}
