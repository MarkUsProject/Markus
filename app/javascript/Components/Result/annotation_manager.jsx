import React from "react";
import {DropDownMenu} from "./dropdown_menu";

export const AnnotationManager = React.memo(function AnnotationManager({
  newAnnotation,
  categories,
  addExistingAnnotation,
}) {
  return (
    <React.Fragment>
      <button key="new_annotation_button" onClick={newAnnotation} title="Shift + N">
        {I18n.t("helpers.submit.create", {
          model: I18n.t("activerecord.models.annotation.one"),
        })}
      </button>
      <ul className="tags" key="annotation_categories">
        {categories.map(cat => (
          <DropDownMenu
            key={cat.id}
            header={cat.annotation_category_name}
            items={cat.texts}
            onItemClick={addExistingAnnotation}
          />
        ))}
      </ul>
    </React.Fragment>
  );
});
